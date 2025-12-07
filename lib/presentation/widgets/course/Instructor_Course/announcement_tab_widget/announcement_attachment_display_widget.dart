// ========================================
// FILE: announcement_attachment_display_widget.dart
// MÔ TẢ: Widget để hiển thị và preview attachments trong announcement
//        (Áp dụng flow của forum_file_preview_widget.dart)
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' show HtmlElementView;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:io' show Platform;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as webview_win;
import '../../../../../core/utils/platform_view_registry.dart' as platform_registry;

/// Widget để hiển thị danh sách attachments trong announcement
class AnnouncementAttachmentDisplayWidget extends StatelessWidget {
  final List<dynamic>? attachments;
  
  const AnnouncementAttachmentDisplayWidget({
    super.key,
    this.attachments,
  });

  void _showPreviewDialog(BuildContext context, List<String> urls, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _AnnouncementFilePreviewDialog(
        fileUrls: urls,
        initialIndex: initialIndex,
      ),
    );
  }

  String _getFileName(String url) {
    try {
      String decodedUrl = Uri.decodeComponent(url);
      decodedUrl = decodedUrl.split('?').first.split('#').first;
      
      final parts = decodedUrl.split('/');
      String fileName = '';
      
      for (var i = parts.length - 1; i >= 0; i--) {
        final part = parts[i].trim();
        if (part.isNotEmpty && part.contains('.') && part != 'o') {
          fileName = part;
          break;
        }
      }
      
      if (fileName.isEmpty) {
        try {
          final uri = Uri.parse(url);
          if (uri.queryParameters.containsKey('name')) {
            fileName = Uri.decodeComponent(uri.queryParameters['name']!);
            fileName = fileName.split('?').first.split('#').first;
          } else {
            final pathSegments = uri.pathSegments;
            if (pathSegments.isNotEmpty) {
              fileName = Uri.decodeComponent(pathSegments.last);
            }
          }
        } catch (e) {
          if (decodedUrl.contains('/')) {
            fileName = decodedUrl.split('/').last;
          } else {
            fileName = decodedUrl;
          }
        }
      }
      
      if (fileName.contains('%2F')) {
        fileName = Uri.decodeComponent(fileName.split('%2F').last);
      }
      
      fileName = fileName.split('?').first.split('#').first;
      if (fileName.contains('/')) {
        fileName = fileName.split('/').last;
      }
      
      return fileName.isNotEmpty ? fileName : 'File';
    } catch (e) {
      return 'File';
    }
  }

  String _getFileType(String url) {
    final fileName = _getFileName(url).toLowerCase();
    if (fileName.endsWith('.pdf')) return 'PDF';
    if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) return 'Document';
    if (fileName.endsWith('.ppt') || fileName.endsWith('.pptx')) return 'Presentation';
    if (fileName.endsWith('.png') || fileName.endsWith('.jpg') || 
        fileName.endsWith('.jpeg') || fileName.endsWith('.gif') || 
        fileName.endsWith('.webp')) return 'Image';
    if (fileName.endsWith('.zip')) return 'Archive';
    
    final urlLower = url.toLowerCase();
    if (urlLower.contains('.pdf')) return 'PDF';
    if (urlLower.contains('.doc')) return 'Document';
    return 'File';
  }

  IconData _getFileIcon(String url) {
    final urlLower = url.toLowerCase();
    if (urlLower.contains('.pdf')) return Icons.picture_as_pdf;
    if (urlLower.contains('.doc')) return Icons.description;
    if (urlLower.contains('.ppt')) return Icons.slideshow;
    if (urlLower.contains('.png') || urlLower.contains('.jpg')) return Icons.image;
    if (urlLower.contains('.zip')) return Icons.folder_zip;
    return Icons.insert_drive_file;
  }

  Color _getFileIconColor(String url) {
    final urlLower = url.toLowerCase();
    if (urlLower.contains('.pdf')) return Colors.red;
    if (urlLower.contains('.doc')) return Colors.blue;
    if (urlLower.contains('.ppt')) return Colors.orange;
    if (urlLower.contains('.png') || urlLower.contains('.jpg')) return Colors.green;
    if (urlLower.contains('.zip')) return Colors.purple;
    return Colors.grey;
  }

  bool _isImage(String url) {
    final fileName = _getFileName(url).toLowerCase();
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || 
        fileName.endsWith('.png') || fileName.endsWith('.gif') ||
        fileName.endsWith('.webp') || fileName.endsWith('.bmp')) {
      return true;
    }
    
    final urlLower = url.toLowerCase();
    if (urlLower.contains('.pdf') || urlLower.contains('.doc')) {
      return false;
    }
    
    return urlLower.contains('.jpg') || urlLower.contains('.png') || 
           urlLower.contains('.jpeg') || urlLower.contains('.gif') ||
           (urlLower.contains('alt=media') && !urlLower.contains('.pdf') && 
            !urlLower.contains('.doc'));
  }

  bool _isPdfOrDoc(String url) {
    final fileName = _getFileName(url).toLowerCase();
    if (fileName.endsWith('.pdf') || fileName.endsWith('.doc') || 
        fileName.endsWith('.docx') || fileName.endsWith('.ppt') || 
        fileName.endsWith('.pptx')) {
      return true;
    }
    
    final urlLower = url.toLowerCase();
    return urlLower.contains('.pdf') || urlLower.contains('.doc') || 
           urlLower.contains('.ppt');
  }

  @override
  Widget build(BuildContext context) {
    if (attachments == null || attachments!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Extract URLs from attachment objects
    final urlList = attachments!.map((attachment) {
      if (attachment is Map) {
        return attachment['url']?.toString() ?? '';
      }
      return attachment.toString();
    }).where((url) => url.isNotEmpty).toList();

    if (urlList.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attachments Header
          Row(
            children: [
              Icon(Icons.attach_file, color: Colors.grey[400], size: 18),
              const SizedBox(width: 6),
              Text(
                'Attachments (${urlList.length})',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Attachments Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: urlList.asMap().entries.map((entry) {
              final index = entry.key;
              final urlStr = entry.value;
              final fileName = _getFileName(urlStr);
              final fileType = _getFileType(urlStr);
              
              final isPdfOrDoc = _isPdfOrDoc(urlStr);
              final isImage = isPdfOrDoc ? false : _isImage(urlStr);

              // Image attachments
              if (isImage) {
                return GestureDetector(
                  onTap: () => _showPreviewDialog(context, urlList, index),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 600,
                        maxHeight: 400,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.network(
                            urlStr,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 600,
                                height: 300,
                                color: Colors.grey[800],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 600,
                                  maxHeight: 300,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.broken_image, 
                                              color: Colors.grey, size: 48),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Cannot load image',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              // PDF/DOC/PPT attachments
              if (isPdfOrDoc) {
                return GestureDetector(
                  onTap: () => _showPreviewDialog(context, urlList, index),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[700]!,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                fileName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getFileIconColor(urlStr).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  fileType,
                                  style: TextStyle(
                                    color: _getFileIconColor(urlStr),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _getFileIconColor(urlStr).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getFileIcon(urlStr),
                            color: _getFileIconColor(urlStr),
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Other file types
              final fileIcon = _getFileIcon(urlStr);
              final fileIconColor = _getFileIconColor(urlStr);

              return GestureDetector(
                onTap: () => _showPreviewDialog(context, urlList, index),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fileType,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 50,
                        height: 45,
                        decoration: BoxDecoration(
                          color: fileIconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          fileIcon,
                          color: fileIconColor,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ========================================
// FILE PREVIEW DIALOG
// ========================================

class _AnnouncementFilePreviewDialog extends StatefulWidget {
  final List<String> fileUrls;
  final int initialIndex;

  const _AnnouncementFilePreviewDialog({
    required this.fileUrls,
    this.initialIndex = 0,
  });

  @override
  State<_AnnouncementFilePreviewDialog> createState() => 
      _AnnouncementFilePreviewDialogState();
}

class _AnnouncementFilePreviewDialogState 
    extends State<_AnnouncementFilePreviewDialog> {
  late int _currentIndex;
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    _transformationController.value = Matrix4.identity()..scale(currentScale * 1.2);
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    _transformationController.value = Matrix4.identity()..scale(currentScale * 0.8);
  }

  String _getFileName(String url) {
    try {
      String decodedUrl = Uri.decodeComponent(url);
      decodedUrl = decodedUrl.split('?').first.split('#').first;
      final parts = decodedUrl.split('/');
      
      for (var i = parts.length - 1; i >= 0; i--) {
        final part = parts[i].trim();
        if (part.isNotEmpty && part.contains('.')) {
          return part;
        }
      }
      return 'File';
    } catch (e) {
      return 'File';
    }
  }

  bool _isImage(String url) {
    final fileName = _getFileName(url).toLowerCase();
    return fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || 
           fileName.endsWith('.png') || fileName.endsWith('.gif') ||
           fileName.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final currentUrl = widget.fileUrls[_currentIndex];
    final fileName = _getFileName(currentUrl);
    final isImage = _isImage(currentUrl);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Background
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.black87,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          
          // Content
          Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[800]!),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.fileUrls.length > 1) ...[
                      IconButton(
                        onPressed: _currentIndex > 0
                            ? () => setState(() {
                                  _currentIndex--;
                                  _resetZoom();
                                })
                            : null,
                        icon: const Icon(Icons.chevron_left, color: Colors.white),
                      ),
                      Text(
                        '${_currentIndex + 1} / ${widget.fileUrls.length}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      IconButton(
                        onPressed: _currentIndex < widget.fileUrls.length - 1
                            ? () => setState(() {
                                  _currentIndex++;
                                  _resetZoom();
                                })
                            : null,
                        icon: const Icon(Icons.chevron_right, color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Content area
              Expanded(
                child: Center(
                  child: isImage
                      ? _ImageViewer(
                          imageUrl: currentUrl,
                          transformationController: _transformationController,
                        )
                      : _FilePreviewContent(
                          fileUrl: currentUrl,
                          fileName: fileName,
                        ),
                ),
              ),
              
              // Zoom controls (for images only)
              if (isImage)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _zoomOut,
                        icon: const Icon(Icons.remove, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          shape: const CircleBorder(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: _resetZoom,
                        icon: const Icon(Icons.fit_screen, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          shape: const CircleBorder(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: _zoomIn,
                        icon: const Icon(Icons.add, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========================================
// IMAGE VIEWER WITH ZOOM
// ========================================

class _ImageViewer extends StatefulWidget {
  final String imageUrl;
  final TransformationController transformationController;

  const _ImageViewer({
    required this.imageUrl,
    required this.transformationController,
  });

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: widget.transformationController,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _isLoading = false);
                });
                return child;
              }
              return child;
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }
}

// ========================================
// FILE PREVIEW CONTENT (PDF/DOC/PPT)
// ========================================

class _FilePreviewContent extends StatefulWidget {
  final String fileUrl;
  final String fileName;

  const _FilePreviewContent({
    required this.fileUrl,
    required this.fileName,
  });

  @override
  State<_FilePreviewContent> createState() => _FilePreviewContentState();
}

class _FilePreviewContentState extends State<_FilePreviewContent> {
  bool _isLoading = true;
  bool _hasError = false;
  WebViewController? _controller;
  webview_win.WebviewController? _windowsController;
  String? _googleDocsUrl;
  String _iframeKey = '';
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeWebView();
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

  String _getPreviewUrl(String url) {
    final encodedUrl = Uri.encodeComponent(url);
    final urlLower = url.toLowerCase();
    
    if (urlLower.contains('.pdf')) {
      return 'https://docs.google.com/viewer?url=$encodedUrl&embedded=true';
    }
    if (urlLower.contains('.docx')) {
      return 'https://docs.google.com/gview?embedded=true&url=$encodedUrl';
    }
    if (urlLower.contains('.doc') && !urlLower.contains('.docx')) {
      return 'https://docs.google.com/gview?embedded=true&url=$encodedUrl';
    }
    if (urlLower.contains('.ppt')) {
      return 'https://docs.google.com/gview?embedded=true&url=$encodedUrl';
    }
    
    return 'https://docs.google.com/viewer?url=$encodedUrl&embedded=true';
  }

  void _initializeWebView() {
    if (widget.fileUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    _googleDocsUrl = _getPreviewUrl(widget.fileUrl);
    _iframeKey = 'announcement-file-${widget.fileName}-${DateTime.now().millisecondsSinceEpoch}';

    if (kIsWeb) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _isLoading) {
          setState(() => _isLoading = false);
        }
      });
      return;
    }

    if (!kIsWeb && Platform.isWindows) {
      _initializeWindowsWebView();
      return;
    }

    if (!kIsWeb && (Platform.isMacOS || Platform.isLinux)) {
      setState(() => _isLoading = false);
      return;
    }

    // Mobile
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_googleDocsUrl!));
  }

  Future<void> _initializeWindowsWebView() async {
    try {
      setState(() => _isLoading = true);
      _windowsController = webview_win.WebviewController();
      await _windowsController!.initialize();
      
      _windowsController!.loadingState.listen((state) {
        if (mounted) {
          setState(() {
            _isLoading = state == webview_win.LoadingState.loading;
          });
        }
      });

      await _windowsController!.loadUrl(_googleDocsUrl!);
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Cannot preview this file',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final uri = Uri.parse(widget.fileUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  // Handle error
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Download File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // WEB
    if (kIsWeb && _googleDocsUrl != null) {
      return Stack(
        children: [
          SizedBox.expand(
            child: Builder(
              builder: (context) {
                platform_registry.registerWebViewFactory(
                  _iframeKey,
                  (int viewId) {
                    final iframe = html.IFrameElement()
                      ..src = _googleDocsUrl!
                      ..style.border = 'none'
                      ..style.width = '100%'
                      ..style.height = '100%'
                      ..allow = 'fullscreen';
                    
                    iframe.onLoad.listen((_) {
                      if (mounted) setState(() => _isLoading = false);
                    });
                    
                    return iframe;
                  },
                );
                
                return HtmlElementView(viewType: _iframeKey);
              },
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black87,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      );
    }

    // MOBILE
    if (_controller != null) {
      return Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_isLoading)
            Container(
              color: Colors.black87,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      );
    }

    // WINDOWS DESKTOP
    if (_windowsController != null && !kIsWeb && Platform.isWindows) {
      return RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: (event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _windowsController!.executeScript('window.scrollBy(0, -50);');
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _windowsController!.executeScript('window.scrollBy(0, 50);');
            }
          }
        },
        child: Stack(
          children: [
            MouseRegion(
              onEnter: (_) => _focusNode.requestFocus(),
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
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
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      );
    }

    // MAC/LINUX - Open in browser
    if (!kIsWeb && (Platform.isMacOS || Platform.isLinux) && _googleDocsUrl != null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.indigo.withOpacity(0.3), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const Text(
                'Open in Browser',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This file will be opened using Google Docs Viewer in your default browser.',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
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
                      // Handle error
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open in Browser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[900],
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Unable to preview this file',
                style: TextStyle(color: Colors.white),
              ),
      ),
    );
  }
}