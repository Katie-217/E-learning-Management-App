import 'dart:io';
import 'dart:convert'; // For utf8
import 'package:flutter/foundation.dart'
    show kIsWeb, consolidateHttpClientResponseBytes;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart'; // For PointerScrollEvent
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:universal_html/html.dart' as html;
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'upload_file_assignment.dart';
import 'web_pdf_helper.dart' as web_helper;
import '../../../../../../core/utils/platform_view_registry.dart'
    as platform_registry;

// Import webview_windows for desktop support
import 'package:webview_windows/webview_windows.dart' as webview_win;

/// Full-screen lightbox overlay to preview files in gallery mode
class FilePreviewOverlay extends StatefulWidget {
  final List<UploadedFileModel> files;
  final int initialIndex;

  const FilePreviewOverlay({
    super.key,
    required this.files,
    this.initialIndex = 0,
  });

  /// Show overlay as full-screen modal
  static Future<void> show(
    BuildContext context,
    List<UploadedFileModel> files, {
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: FilePreviewOverlay(
              files: files,
              initialIndex: initialIndex,
            ),
          );
        },
      ),
    );
  }

  @override
  State<FilePreviewOverlay> createState() => _FilePreviewOverlayState();
}

class _FilePreviewOverlayState extends State<FilePreviewOverlay> {
  late int _currentIndex;
  late PageController _pageController;
  bool _showHeader = true; // Toggle header visibility for images

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  UploadedFileModel get _currentFile => widget.files[_currentIndex];

  bool _isOfficeFile(UploadedFileModel file) {
    final ext = file.fileExtension.toLowerCase();
    return ['.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'].contains(ext);
  }

  void _nextFile() {
    if (_currentIndex < widget.files.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousFile() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.95),
      child: SafeArea(
        child: Column(
          children: [
            // Header with gradient background (hide-able for images)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _showHeader ? null : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showHeader ? 1.0 : 0.0,
                child: _buildHeader(context),
              ),
            ),

            // Main content with PageView for swipe navigation
            Expanded(
              child: Stack(
                children: [
                  // PageView for swipeable gallery
                  PageView.builder(
                    controller: _pageController,
                    physics: _isOfficeFile(_currentFile)
                        ? const NeverScrollableScrollPhysics() // Disable swipe for Office files
                        : const PageScrollPhysics(), // Normal swipe for other files
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                        _showHeader =
                            true; // Reset header visibility on page change
                      });
                    },
                    itemCount: widget.files.length,
                    itemBuilder: (context, index) {
                      final file = widget.files[index];
                      return GestureDetector(
                        onTap: file.isImage ? _toggleHeader : null,
                        child: Container(
                          color: Colors.transparent,
                          child: _buildContentForFile(context, file),
                        ),
                      );
                    },
                  ),

                  // Navigation arrows - Always visible at all screen sizes
                  // Wrapped with PointerInterceptor to work on web with iframes
                  // Previous button
                  if (_currentIndex > 0)
                    Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: PointerInterceptor(
                          child: Material(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(30),
                            child: InkWell(
                              onTap: _previousFile,
                              borderRadius: BorderRadius.circular(30),
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.chevron_left,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Next button
                  if (_currentIndex < widget.files.length - 1)
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: PointerInterceptor(
                          child: Material(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(30),
                            child: InkWell(
                              onTap: _nextFile,
                              borderRadius: BorderRadius.circular(30),
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // File counter indicator (e.g., "2 / 5")
            // Wrapped with PointerInterceptor to work on web
            if (widget.files.length > 1)
              PointerInterceptor(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.files.length}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleHeader() {
    setState(() {
      _showHeader = !_showHeader;
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Icon(
            FileUploadService.getFileIcon(_currentFile.fileExtension),
            color: FileUploadService.getFileColor(_currentFile.fileExtension),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentFile.fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  _currentFile.formattedSize,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Close button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(24),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentForFile(BuildContext context, UploadedFileModel file) {
    // Route to appropriate viewer based on file type
    if (file.isImage) {
      return _ImageViewer(file: file);
    } else if (file.isText || _isCodeFile(file.fileExtension)) {
      return _TextCodeViewer(file: file);
    } else if (file.isPdf) {
      return _PdfViewer(file: file);
    } else if (FileUploadService.isOfficeFile(file.fileExtension)) {
      return _OfficeViewer(file: file);
    } else {
      return _UnsupportedFileViewer(file: file);
    }
  }

  bool _isCodeFile(String extension) {
    const codeExtensions = [
      // Programming languages
      '.dart', '.java', '.py', '.js', '.ts', '.cpp', '.c', '.h',
      '.cs', '.php', '.rb', '.go', '.rs', '.swift', '.kt',
      // Web
      '.html', '.css', '.scss', '.json', '.xml', '.yaml', '.yml',
      // Scripts & Shell
      '.sh', '.bat', '.sql', '.md',
      // Data files (Important for IT students)
      '.csv', '.tsv',
      // Documents
      '.txt', '.rtf',
      // Config & System files (Common in IT projects)
      '.env', '.gitignore', '.properties', '.gradle', '.ini', '.conf',
      // Logs
      '.log',
    ];
    return codeExtensions.contains(extension.toLowerCase());
  }
}

/// Image viewer with zoom/pan support
class _ImageViewer extends StatelessWidget {
  final UploadedFileModel file;

  const _ImageViewer({required this.file});

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // Priority order for Web:
    // 1. Firebase URL (after upload) -> use network
    // 2. Local bytes (before upload) -> use memory
    // 3. Fallback -> show error

    // Priority order for Desktop/Mobile:
    // 1. Firebase URL (after upload) -> use network
    // 2. Local file path -> use file
    // 3. Fallback -> show error

    if (file.filePath.isNotEmpty &&
        (file.filePath.startsWith('http://') ||
            file.filePath.startsWith('https://'))) {
      // Firebase URL (uploaded) - works on ALL platforms
      print('🖼️ _ImageViewer using Image.network: ${file.fileName}');
      imageWidget = Image.network(
        file.filePath,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Image.network error: $error');
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Failed to load image:\n$error',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    } else if (kIsWeb && file.fileBytes != null && file.fileBytes!.isNotEmpty) {
      // Web with local bytes (before upload)
      print('🖼️ _ImageViewer on Web using Image.memory: ${file.fileName}');
      imageWidget = Image.memory(
        file.fileBytes!,
        fit: BoxFit.contain,
      );
    } else if (!kIsWeb && file.filePath.isNotEmpty) {
      // Local file path (Desktop/Mobile ONLY - NOT Web!)
      print(
          '🖼️ _ImageViewer on Desktop/Mobile using Image.file: ${file.fileName}');
      imageWidget = Image.file(
        File(file.filePath),
        fit: BoxFit.contain,
      );
    } else {
      // Fallback - no valid image source
      print('❌ _ImageViewer: No valid image source for ${file.fileName}');
      print('   - filePath: ${file.filePath}');
      print('   - fileBytes: ${file.fileBytes?.length ?? 'null'}');
      print('   - kIsWeb: $kIsWeb');
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image, color: Colors.white54, size: 64),
            SizedBox(height: 16),
            Text(
              'Image not available',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: imageWidget,
    );
  }
}

/// Text and code viewer with syntax highlighting
class _TextCodeViewer extends StatelessWidget {
  final UploadedFileModel file;

  const _TextCodeViewer({required this.file});

  @override
  Widget build(BuildContext context) {
    // Case 1: Web platform with bytes available
    if (kIsWeb && file.fileBytes != null) {
      return _buildTextContent(
        context,
        String.fromCharCodes(file.fileBytes!),
      );
    }

    // Case 2: File has URL (uploaded to Firebase) - need to download
    if (file.filePath.startsWith('http://') ||
        file.filePath.startsWith('https://')) {
      return FutureBuilder<String>(
        future: _downloadTextFromUrl(file.filePath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Downloading file content...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Error downloading file:\n${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return _buildTextContent(context, snapshot.data ?? '');
        },
      );
    }

    // Case 3: Local file path - read from file system
    if (file.filePath.isNotEmpty) {
      return FutureBuilder<String>(
        future: File(file.filePath).readAsString(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading file:\n${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return _buildTextContent(context, snapshot.data ?? '');
        },
      );
    }

    return const Center(
      child: Text(
        'File not available',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  /// Download text content from URL
  Future<String> _downloadTextFromUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        return utf8.decode(bytes);
      } else {
        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Download error: $e');
    }
  }

  Widget _buildTextContent(BuildContext context, String content) {
    return Container(
      width: double.infinity, // Full width
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1E1E1E), // VS Code dark theme
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Copy button aligned to right
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Code content with line numbers (scrollable with always-visible scrollbars on Desktop)
          Expanded(
            child: Scrollbar(
              thumbVisibility: true, // Always show scrollbar on Desktop
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildCodeWithLineNumbers(content),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeWithLineNumbers(String content) {
    final lines = content.split('\n');
    final lineCount = lines.length;
    final lineNumberWidth = (lineCount.toString().length * 10.0) + 20;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line numbers
        Container(
          width: lineNumberWidth,
          padding: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey[700]!, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              lineCount,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Code content
        SelectableText(
          content,
          style: const TextStyle(
            color: Color(0xFFD4D4D4), // VS Code default text color
            fontSize: 14,
            fontFamily: 'monospace',
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Global cache for Blob URLs to prevent revoke issues when reopening PDF
final Map<String, String> _globalBlobUrlCache = {};

/// PDF viewer - Native browser renderer for web, Syncfusion for mobile/desktop
class _PdfViewer extends StatefulWidget {
  final UploadedFileModel file;

  const _PdfViewer({required this.file});

  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  String? _errorMessage;
  String? _blobUrl; // For web only

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // On web: Check if we have bytes OR a Firebase URL
      if (widget.file.fileBytes != null) {
        _getBlobUrlForWeb();
      } else if (widget.file.filePath.startsWith('http')) {
        // File already uploaded to Firebase - use URL directly
        _blobUrl = widget.file.filePath;
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    // DO NOT revoke Blob URL - keep it cached for reuse
    // URLs will be cleaned up when app closes
    super.dispose();
  }

  void _getBlobUrlForWeb() {
    try {
      // Check cache first to reuse existing Blob URL
      final cacheKey = widget.file.fileName;
      if (_globalBlobUrlCache.containsKey(cacheKey)) {
        _blobUrl = _globalBlobUrlCache[cacheKey]!;
        print('Reusing cached Blob URL for: $cacheKey');
        setState(() {});
        return;
      }

      // Create new Blob URL and cache it
      final bytes = widget.file.fileBytes!;
      final blob = html.Blob([bytes], 'application/pdf');
      _blobUrl = html.Url.createObjectUrlFromBlob(blob);
      _globalBlobUrlCache[cacheKey] = _blobUrl!;
      print('Created and cached Blob URL for: $cacheKey');

      // Register view factory for HtmlElementView (web only)
      final viewType = 'pdf-iframe-${widget.file.fileName.hashCode}';
      web_helper.registerPdfViewFactory(viewType, _blobUrl!);

      setState(() {});
    } catch (e) {
      print('Error creating Blob URL: $e');
      setState(() {
        _errorMessage = 'Failed to create PDF preview: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // On web, use native browser PDF viewer via iframe
    if (kIsWeb) {
      print('_PdfViewer on web: fileName=${widget.file.fileName}');
      print('_PdfViewer filePath=${widget.file.filePath}');
      print(
          '_PdfViewer fileBytes: ${widget.file.fileBytes != null ? '${widget.file.fileBytes!.length} bytes' : 'NULL'}');

      // Check if we have PDF data (bytes OR URL)
      final hasBytes =
          widget.file.fileBytes != null && widget.file.fileBytes!.isNotEmpty;
      final hasUrl = widget.file.filePath.startsWith('http');

      if (!hasBytes && !hasUrl) {
        print('_PdfViewer: No bytes or URL available - showing fallback');
        return _buildFallback(context, 'No PDF data available');
      }

      // Show error if load failed
      if (_errorMessage != null) {
        return _buildFallback(context, _errorMessage!);
      }

      // Wait for blob URL to be ready
      if (_blobUrl == null) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }

      // Use iframe to display PDF (works with both Blob URL and Firebase URL)
      final viewType = 'pdf-iframe-${widget.file.fileName.hashCode}';

      // Register view factory if not already registered
      if (hasUrl && _blobUrl == widget.file.filePath) {
        // Using Firebase URL directly - register iframe
        web_helper.registerPdfViewFactory(viewType, _blobUrl!);
      }

      return HtmlElementView(viewType: viewType);
    }

    // On mobile/desktop: Check if file is URL or local path
    if (widget.file.filePath.isNotEmpty) {
      // If filePath is a URL (from Firebase Storage), use SfPdfViewer.network
      if (widget.file.filePath.startsWith('http://') ||
          widget.file.filePath.startsWith('https://')) {
        return SfPdfViewer.network(
          widget.file.filePath,
          enableDoubleTapZooming: true,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            print('PDF Load Failed: ${details.error}');
            setState(() {
              _errorMessage = 'Failed to load PDF: ${details.description}';
            });
          },
        );
      } else {
        // Local file path: use SfPdfViewer.file
        return SfPdfViewer.file(
          File(widget.file.filePath),
          enableDoubleTapZooming: true,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            print('PDF Load Failed: ${details.error}');
            setState(() {
              _errorMessage = 'Failed to load PDF: ${details.description}';
            });
          },
        );
      }
    }

    // Fallback if no file data available
    return _buildFallback(context, 'File path not available for preview');
  }

  Widget _buildFallback(BuildContext context, String message) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.picture_as_pdf,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              widget.file.fileName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.file.formattedSize,
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Viewer for unsupported file types
class _UnsupportedFileViewer extends StatelessWidget {
  final UploadedFileModel file;

  const _UnsupportedFileViewer({required this.file});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FileUploadService.getFileIcon(file.fileExtension),
              size: 80,
              color: FileUploadService.getFileColor(file.fileExtension),
            ),
            const SizedBox(height: 24),
            Text(
              file.fileName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              file.formattedSize,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'This file type (${file.fileExtension}) cannot be previewed in-app.\nPlease open it with an external application.',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openExternally(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Externally'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                if (kIsWeb) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _downloadFile(context),
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternally(BuildContext context) async {
    try {
      if (kIsWeb) {
        // On web, try to open the file URL if available
        if (file.filePath.startsWith('http')) {
          final uri = Uri.parse(file.filePath);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cannot open file URL')),
              );
            }
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File is not uploaded yet')),
            );
          }
        }
      } else {
        // On mobile/desktop, open local file path
        if (file.filePath.isNotEmpty) {
          // For remote URLs (uploaded files)
          if (file.filePath.startsWith('http')) {
            final uri = Uri.parse(file.filePath);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cannot open file URL')),
                );
              }
            }
          } else {
            // For local files
            final uri = Uri.file(file.filePath);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cannot open file')),
                );
              }
            }
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File path not available')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  void _downloadFile(BuildContext context) {
    // For web, trigger download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading file...')),
    );
  }
}

/// Office file viewer using Google Docs Viewer
class _OfficeViewer extends StatefulWidget {
  final UploadedFileModel file;

  const _OfficeViewer({required this.file});

  @override
  State<_OfficeViewer> createState() => _OfficeViewerState();
}

class _OfficeViewerState extends State<_OfficeViewer> {
  WebViewController? _controller; // For Mobile (iOS/Android)
  webview_win.WebviewController? _windowsController; // For Windows Desktop
  bool _isLoading = true;
  String? _googleDocsUrl; // Store Google Docs Viewer URL
  String _iframeKey = ''; // Unique key for iframe to force reload
  final FocusNode _focusNode =
      FocusNode(); // Add FocusNode for keyboard/mouse events

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    // Auto-focus to receive scroll events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _windowsController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_OfficeViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if file changes
    if (oldWidget.file.filePath != widget.file.filePath) {
      _initializeWebView();
    }
  }

  void _initializeWebView() {
    final String? fileUrl = _getPublicUrl();

    if (fileUrl != null) {
      // IMPORTANT: Firebase URLs have query params (?alt=media&token=...)
      // Must encode entire URL to preserve these params in viewer
      final encodedUrl = Uri.encodeComponent(fileUrl);

      // Use Google Docs Viewer for all Office documents
      // Google Docs Viewer is more reliable than Office Web Viewer
      _googleDocsUrl =
          'https://docs.google.com/gview?embedded=true&url=$encodedUrl';

      // Generate unique key for iframe to force reload on file change
      _iframeKey =
          'office-${widget.file.fileName}-${DateTime.now().millisecondsSinceEpoch}';

      // For Web: Use iframe (handled in build method)
      if (kIsWeb) {
        setState(() {
          _isLoading = true; // Keep loading until iframe loads
        });

        // Fallback: Hide loading after 5 seconds even if load event doesn't fire
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _isLoading) {
            setState(() {
              _isLoading = false;
            });
          }
        });
        return;
      }

      // For Desktop (Windows/Mac/Linux): Use webview_windows for Windows, fallback for others
      if (Platform.isWindows) {
        _initializeWindowsWebView();
        return;
      }

      if (Platform.isMacOS || Platform.isLinux) {
        setState(() {
          _isLoading = false; // Mark as ready to show info banner for Mac/Linux
        });
        return;
      }

      // For Mobile (Android/iOS): Use WebView for in-app preview
      // Mobile has proper WebView support
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
              });
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Error loading file: ${error.description}')),
                );
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(_googleDocsUrl!));
    }
  }

  // Initialize Windows WebView (Desktop)
  Future<void> _initializeWindowsWebView() async {
    try {
      setState(() {
        _isLoading = true;
      });

      _windowsController = webview_win.WebviewController();
      await _windowsController!.initialize();

      // Set up navigation delegate
      _windowsController!.loadingState.listen((state) {
        if (mounted) {
          setState(() {
            _isLoading = state == webview_win.LoadingState.loading;
          });
        }
      });

      // Load Google Docs Viewer URL
      await _windowsController!.loadUrl(_googleDocsUrl!);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing Windows WebView: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _getPublicUrl() {
    // Check if filePath is an online URL (starts with http/https)
    if (widget.file.filePath.isNotEmpty &&
        (widget.file.filePath.startsWith('http://') ||
            widget.file.filePath.startsWith('https://'))) {
      return widget.file.filePath;
    }

    // Otherwise, it's a local file
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String? fileUrl = _getPublicUrl();

    // Local file: no URL and either has path (mobile/desktop) or has bytes (web)
    final bool isLocalFile = fileUrl == null &&
        (widget.file.filePath.isNotEmpty || widget.file.fileBytes != null);

    if (isLocalFile) {
      // File is local (still uploading or upload failed)
      return Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                FileUploadService.getFileIcon(widget.file.fileExtension),
                size: 80,
                color:
                    FileUploadService.getFileColor(widget.file.fileExtension),
              ),
              const SizedBox(height: 16),
              Text(
                widget.file.fileName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.file.formattedSize,
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              // Show upload status message
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'File đang upload lên Firebase Storage...',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Vui lòng đợi upload hoàn tất để xem preview',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Remote file with URL - show preview based on platform
    if (fileUrl != null && _googleDocsUrl != null) {
      // WEB PLATFORM: Use iframe with Google Docs Viewer
      if (kIsWeb) {
        return Stack(
          children: [
            // Create iframe using HtmlElementView
            SizedBox.expand(
              child: Builder(
                builder: (context) {
                  // Use unique key for each file to force iframe reload
                  final viewType = _iframeKey;

                  // Register view factory with unique key
                  platform_registry.registerWebViewFactory(
                    viewType,
                    (int viewId) {
                      final iframe = html.IFrameElement()
                        ..src = _googleDocsUrl!
                        ..style.border = 'none'
                        ..style.width = '100%'
                        ..style.height = '100%'
                        ..allow = 'fullscreen';

                      // Handle load events to hide loading indicator
                      iframe.onLoad.listen((_) {
                        print('DEBUG: Iframe loaded successfully');
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      });

                      // Handle error events
                      iframe.onError.listen((error) {
                        print('DEBUG: Iframe error - $error');
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Error loading document. Please try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      });

                      return iframe;
                    },
                  );

                  return HtmlElementView(viewType: viewType);
                },
              ),
            ),
            // Loading indicator with message
            if (_isLoading)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          color: Colors.indigo,
                          strokeWidth: 4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Loading document...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait while Google Docs Viewer loads the file',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }

      // MOBILE PLATFORMS: Use WebView with Google Docs Viewer
      if (_controller != null) {
        return Stack(
          children: [
            WebViewWidget(controller: _controller!),
            if (_isLoading)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          color: Colors.indigo,
                          strokeWidth: 4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Loading document...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait while Google Docs Viewer loads the file',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }

      // WINDOWS DESKTOP: Use webview_windows with enhanced scroll support
      if (_windowsController != null && Platform.isWindows) {
        return RawKeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKey: (event) {
            // Handle arrow keys for scrolling
            if (event is RawKeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _windowsController!.executeScript('window.scrollBy(0, -50);');
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _windowsController!.executeScript('window.scrollBy(0, 50);');
              } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
                _windowsController!
                    .executeScript('window.scrollBy(0, -window.innerHeight);');
              } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
                _windowsController!
                    .executeScript('window.scrollBy(0, window.innerHeight);');
              }
            }
          },
          child: Stack(
            children: [
              // Wrap with MouseRegion to capture all mouse events
              MouseRegion(
                onEnter: (_) {
                  // Request focus when mouse enters WebView area
                  _focusNode.requestFocus();
                },
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      // Inject JavaScript to scroll - with smoother delta
                      final scrollDelta = event.scrollDelta.dy;
                      _windowsController!.executeScript(
                        'window.scrollBy({top: $scrollDelta, left: 0, behavior: "auto"});',
                      );
                    }
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: webview_win.Webview(_windowsController!),
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            color: Colors.indigo,
                            strokeWidth: 4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Loading document...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please wait while Google Docs Viewer loads the file',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      }

      // MAC/LINUX FALLBACK: Show info banner with "Open in Browser" button
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.indigo.withOpacity(0.3), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.open_in_browser,
                  size: 40,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              const Text(
                'Open in Browser',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                'This Office file will be opened using Google Docs Viewer in your default browser.',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // File info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.indigo.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      FileUploadService.getFileIcon(widget.file.fileExtension),
                      color: FileUploadService.getFileColor(
                          widget.file.fileExtension),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.file.fileName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.file.formattedSize,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Open button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await launchUrl(
                        Uri.parse(_googleDocsUrl!),
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Cannot open browser: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text(
                    'Open in Browser',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback - shouldn't reach here
    return const Center(
      child: Text(
        'Unable to preview this file',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
