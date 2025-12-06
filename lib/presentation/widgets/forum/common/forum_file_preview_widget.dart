// ========================================
// FILE: forum_file_preview_widget.dart
// MÔ TẢ: Widget dùng chung để preview file cho forum (Student và Instructor)
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' show HtmlElementView;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart'; // For PointerScrollEvent
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:io' show Platform;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as webview_win;
import '../../../../core/utils/platform_view_registry.dart' as platform_registry;

class AttachmentDisplayWidget extends StatelessWidget {
  final List<dynamic>? attachments;
  const AttachmentDisplayWidget({super.key, this.attachments});

  void _showPreviewDialog(BuildContext context, List<String> urls, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => FilePreviewDialog(
        fileUrls: urls,
        initialIndex: initialIndex,
      ),
    );
  }

  String _getFileName(String url) {
    try {
      // Decode URL trước
      String decodedUrl = Uri.decodeComponent(url);
      
      // Loại bỏ query parameters và hash
      decodedUrl = decodedUrl.split('?').first;
      decodedUrl = decodedUrl.split('#').first;
      
      // Tách path bằng / và lấy phần cuối cùng (tên file)
      final parts = decodedUrl.split('/');
      String fileName = '';
      
      // Tìm phần cuối cùng có chứa dấu chấm (extension)
      for (var i = parts.length - 1; i >= 0; i--) {
        final part = parts[i].trim();
        if (part.isNotEmpty && part.contains('.') && part != 'o') {
          fileName = part;
          break;
        }
      }
      
      // Nếu không tìm thấy, thử lấy từ path segments của URI
      if (fileName.isEmpty) {
        try {
          final uri = Uri.parse(url);
          // Kiểm tra query parameter 'name' trước
          if (uri.queryParameters.containsKey('name')) {
            fileName = uri.queryParameters['name']!;
            fileName = Uri.decodeComponent(fileName);
            fileName = fileName.split('?').first;
            fileName = fileName.split('#').first;
          } else {
            // Lấy từ path segments
            final pathSegments = uri.pathSegments;
            if (pathSegments.isNotEmpty) {
              fileName = pathSegments.last;
              fileName = Uri.decodeComponent(fileName);
            }
          }
        } catch (e) {
          // Fallback: lấy phần cuối của URL
          if (decodedUrl.contains('/')) {
            fileName = decodedUrl.split('/').last;
          } else {
            fileName = decodedUrl;
          }
        }
      }
      
      // Xử lý %2F (encoded /) - chỉ lấy phần cuối
      if (fileName.contains('%2F')) {
        final encodedParts = fileName.split('%2F');
        fileName = encodedParts.last;
        fileName = Uri.decodeComponent(fileName);
      }
      
      // Loại bỏ query parameters và hash một lần nữa
      fileName = fileName.split('?').first;
      fileName = fileName.split('#').first;
      
      // Đảm bảo chỉ trả về tên file, không có đường dẫn
      if (fileName.contains('/')) {
        fileName = fileName.split('/').last;
      }
      
      return fileName.isNotEmpty ? fileName : 'File';
    } catch (e) {
      return 'File';
    }
  }

  String _getFileType(String url) {
    // Ưu tiên kiểm tra extension từ tên file
    final fileName = _getFileName(url).toLowerCase();
    if (fileName.endsWith('.pdf')) {
      return 'PDF';
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return 'Document';
    } else if (fileName.endsWith('.png') || 
               fileName.endsWith('.jpg') || 
               fileName.endsWith('.jpeg') ||
               fileName.endsWith('.gif') ||
               fileName.endsWith('.webp')) {
      return 'Hình ảnh';
    }
    
    // Fallback: Kiểm tra URL
    final urlLower = url.toLowerCase();
    if (urlLower.contains('.pdf')) {
      return 'PDF';
    } else if (urlLower.contains('.doc') || urlLower.contains('.docx')) {
      return 'Document';
    } else if (urlLower.contains('.png') || urlLower.contains('.jpg') || urlLower.contains('.jpeg')) {
      return 'Hình ảnh';
    } else {
      return 'File';
    }
  }

  IconData _getFileIcon(String url) {
    final urlLower = url.toLowerCase();
    if (urlLower.contains('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (urlLower.contains('.doc') || urlLower.contains('.docx')) {
      return Icons.description;
    } else if (urlLower.contains('.png') || urlLower.contains('.jpg') || urlLower.contains('.jpeg')) {
      return Icons.image;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String url) {
    final urlLower = url.toLowerCase();
    if (urlLower.contains('.pdf')) {
      return Colors.red;
    } else if (urlLower.contains('.doc') || urlLower.contains('.docx')) {
      return Colors.blue;
    } else if (urlLower.contains('.png') || urlLower.contains('.jpg') || urlLower.contains('.jpeg')) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  bool _isImage(String url) {
    // Ưu tiên kiểm tra extension từ tên file
    final fileName = _getFileName(url).toLowerCase();
    if (fileName.endsWith('.jpg') || 
        fileName.endsWith('.jpeg') || 
        fileName.endsWith('.png') || 
        fileName.endsWith('.gif') ||
        fileName.endsWith('.webp') ||
        fileName.endsWith('.bmp')) {
      return true;
    }
    
    // Kiểm tra URL nếu không tìm thấy extension trong tên file
    final urlLower = url.toLowerCase();
    // Chỉ coi là image nếu có extension image và KHÔNG phải PDF/DOC
    if (urlLower.contains('.pdf') || urlLower.contains('.doc')) {
      return false; // PDF/DOC không phải image
    }
    
    return urlLower.contains('.jpg') || 
           urlLower.contains('.png') || 
           urlLower.contains('.jpeg') ||
           urlLower.contains('.gif') ||
           (urlLower.contains('alt=media') && !urlLower.contains('.pdf') && !urlLower.contains('.doc'));
  }

  bool _isPdfOrDoc(String url) {
    // Ưu tiên kiểm tra extension từ tên file
    final fileName = _getFileName(url).toLowerCase();
    if (fileName.endsWith('.pdf') || 
        fileName.endsWith('.doc') || 
        fileName.endsWith('.docx')) {
      return true;
    }
    
    // Kiểm tra URL nếu không tìm thấy extension trong tên file
    final urlLower = url.toLowerCase();
    return urlLower.contains('.pdf') || 
           urlLower.contains('.doc') || 
           urlLower.contains('.docx');
  }

  @override
  Widget build(BuildContext context) {
    if (attachments == null || attachments!.isEmpty) return const SizedBox.shrink();

    final urlList = attachments!.map((url) => url.toString()).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: attachments!.asMap().entries.map((entry) {
          final index = entry.key;
          final urlStr = entry.value.toString();
          final fileName = _getFileName(urlStr);
          final fileType = _getFileType(urlStr);
          
          // Xác định loại file: ưu tiên PDF/DOC trước (vì PDF có thể bị nhầm là image)
          final isPdfOrDoc = _isPdfOrDoc(urlStr);
          final isImage = isPdfOrDoc ? false : _isImage(urlStr); // Nếu là PDF/DOC thì không phải image

          // Nếu là hình ảnh, hiển thị với kích thước phù hợp
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
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // Nếu load lỗi, kiểm tra lại xem có phải là PDF/DOC không
                          final recheckIsPdfOrDoc = _isPdfOrDoc(urlStr);
                          if (recheckIsPdfOrDoc) {
                            // Nếu thực ra là PDF/DOC, hiển thị như PDF/DOC
                            return GestureDetector(
                              onTap: () => _showPreviewDialog(context, urlList, index),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                      spreadRadius: 0,
                                    ),
                                  ],
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
                                              color: Colors.black87,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              decoration: TextDecoration.underline,
                                              decorationColor: Colors.blue,
                                              height: 1.3,
                                              letterSpacing: -0.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: fileType == 'PDF' 
                                                  ? Colors.red[50] 
                                                  : Colors.blue[50],
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              fileType,
                                              style: TextStyle(
                                                color: fileType == 'PDF' 
                                                    ? Colors.red[700] 
                                                    : Colors.blue[700],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _PdfDocThumbnail(
                                      fileUrl: urlStr,
                                      width: 80,
                                      height: 60,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          // Nếu thực sự là image nhưng load lỗi
                          return Container(
                            constraints: const BoxConstraints(
                              maxWidth: 600,
                              maxHeight: 300,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image, color: Colors.grey, size: 48),
                                const SizedBox(height: 8),
                                Text(
                                  'Không thể tải hình ảnh',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    fileName,
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
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

          // Nếu là PDF hoặc DOC, hiển thị card đẹp với thumbnail preview
          if (isPdfOrDoc) {
            return GestureDetector(
              onTap: () => _showPreviewDialog(context, urlList, index),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left side: File name and type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fileName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue.shade300,
                              height: 1.4,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: fileType == 'PDF' 
                                  ? Colors.red.shade400.withOpacity(0.2)
                                  : Colors.blue.shade400.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: fileType == 'PDF' 
                                    ? Colors.red.shade300.withOpacity(0.5)
                                    : Colors.blue.shade300.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              fileType,
                              style: TextStyle(
                                color: fileType == 'PDF' 
                                    ? Colors.red.shade200
                                    : Colors.blue.shade200,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Right side: PDF/DOC thumbnail preview
                    const SizedBox(width: 12),
                    _PdfDocThumbnail(
                      fileUrl: urlStr,
                      width: 80,
                      height: 60,
                    ),
                  ],
                ),
              ),
            );
          }

          // Các file khác: Hiển thị như cũ (card xám với icon)
          final fileIcon = _getFileIcon(urlStr);
          final fileIconColor = _getFileIconColor(urlStr);

          return GestureDetector(
            onTap: () => _showPreviewDialog(context, urlList, index),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[700]!,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                    width: 60,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
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
    );
  }
}

// Widget để hiển thị thumbnail preview cho PDF/DOC
class _PdfDocThumbnail extends StatefulWidget {
  final String fileUrl;
  final double width;
  final double height;

  const _PdfDocThumbnail({
    required this.fileUrl,
    required this.width,
    required this.height,
  });

  @override
  State<_PdfDocThumbnail> createState() => _PdfDocThumbnailState();
}

class _PdfDocThumbnailState extends State<_PdfDocThumbnail> {
  @override
  Widget build(BuildContext context) {
    // Sử dụng Flutter widgets thuần để hiển thị thumbnail
    final urlLower = widget.fileUrl.toLowerCase();
    final isPdf = urlLower.contains('.pdf');
    final isDoc = urlLower.contains('.doc');
    
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isPdf
                    ? [Colors.red.shade50, Colors.red.shade100]
                    : [Colors.blue.shade50, Colors.blue.shade100],
              ),
            ),
          ),
          // Icon và text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.description,
                  color: isPdf ? Colors.red.shade700 : Colors.blue.shade700,
                  size: 28,
                ),
                const SizedBox(height: 2),
                Text(
                  isPdf ? 'PDF' : 'DOC',
                  style: TextStyle(
                    color: isPdf ? Colors.red.shade700 : Colors.blue.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// File Preview Dialog với header, controls và navigation
class FilePreviewDialog extends StatefulWidget {
  final List<String> fileUrls;
  final int initialIndex;

  const FilePreviewDialog({
    super.key,
    required this.fileUrls,
    this.initialIndex = 0,
  });

  @override
  State<FilePreviewDialog> createState() => _FilePreviewDialogState();
}

/// Image viewer with zoom/pan support and loading indicator
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
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image with InteractiveViewer
        InteractiveViewer(
          transformationController: widget.transformationController,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                // Image loaded successfully
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                      _hasError = false;
                    });
                  }
                });
                return child;
              }
              // Still loading
              return child;
            },
            errorBuilder: (context, error, stackTrace) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _hasError = true;
                  });
                }
              });
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Loading indicator
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading image...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FilePreviewDialogState extends State<FilePreviewDialog> {
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
      // Decode URL trước
      String decodedUrl = Uri.decodeComponent(url);
      
      // Loại bỏ query parameters và hash
      decodedUrl = decodedUrl.split('?').first;
      decodedUrl = decodedUrl.split('#').first;
      
      // Tách path bằng / và lấy phần cuối cùng (tên file)
      final parts = decodedUrl.split('/');
      String fileName = '';
      
      // Tìm phần cuối cùng có chứa dấu chấm (extension)
      for (var i = parts.length - 1; i >= 0; i--) {
        final part = parts[i].trim();
        if (part.isNotEmpty && part.contains('.') && part != 'o') {
          fileName = part;
          break;
        }
      }
      
      // Nếu không tìm thấy, thử lấy từ path segments của URI
      if (fileName.isEmpty) {
        try {
          final uri = Uri.parse(url);
          // Kiểm tra query parameter 'name' trước
          if (uri.queryParameters.containsKey('name')) {
            fileName = uri.queryParameters['name']!;
            fileName = Uri.decodeComponent(fileName);
            fileName = fileName.split('?').first;
            fileName = fileName.split('#').first;
          } else {
            // Lấy từ path segments
            final pathSegments = uri.pathSegments;
            if (pathSegments.isNotEmpty) {
              fileName = pathSegments.last;
              fileName = Uri.decodeComponent(fileName);
            }
          }
        } catch (e) {
          // Fallback: lấy phần cuối của URL
          if (decodedUrl.contains('/')) {
            fileName = decodedUrl.split('/').last;
          } else {
            fileName = decodedUrl;
          }
        }
      }
      
      // Xử lý %2F (encoded /) - chỉ lấy phần cuối
      if (fileName.contains('%2F')) {
        final encodedParts = fileName.split('%2F');
        fileName = encodedParts.last;
        fileName = Uri.decodeComponent(fileName);
      }
      
      // Loại bỏ query parameters và hash một lần nữa
      fileName = fileName.split('?').first;
      fileName = fileName.split('#').first;
      
      // Đảm bảo chỉ trả về tên file, không có đường dẫn
      if (fileName.contains('/')) {
        fileName = fileName.split('/').last;
      }
      
      return fileName.isNotEmpty ? fileName : 'File';
    } catch (e) {
      return 'File';
    }
  }

  bool _isImage(String url) {
    // Ưu tiên kiểm tra extension từ tên file
    final fileName = _getFileName(url).toLowerCase();
    if (fileName.endsWith('.jpg') || 
        fileName.endsWith('.jpeg') || 
        fileName.endsWith('.png') || 
        fileName.endsWith('.gif') ||
        fileName.endsWith('.webp') ||
        fileName.endsWith('.bmp')) {
      return true;
    }
    
    // Kiểm tra URL nếu không tìm thấy extension trong tên file
    final urlLower = url.toLowerCase();
    // Chỉ coi là image nếu có extension image và KHÔNG phải PDF/DOC
    if (urlLower.contains('.pdf') || urlLower.contains('.doc')) {
      return false; // PDF/DOC không phải image
    }
    
    return urlLower.contains('.jpg') || 
           urlLower.contains('.png') || 
           urlLower.contains('.jpeg') ||
           urlLower.contains('.gif') ||
           (urlLower.contains('alt=media') && !urlLower.contains('.pdf') && !urlLower.contains('.doc'));
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[800]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Text(
                        '${_currentIndex + 1} / ${widget.fileUrls.length}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      IconButton(
                        onPressed: _currentIndex < widget.fileUrls.length - 1
                            ? () => setState(() {
                                  _currentIndex++;
                                  _resetZoom();
                                })
                            : null,
                        icon: const Icon(Icons.chevron_right, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
              // Controls (chỉ hiển thị cho images)
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
          // Navigation arrows (nếu có nhiều files)
          if (widget.fileUrls.length > 1) ...[
            // Left arrow
            if (_currentIndex > 0)
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _currentIndex--;
                        _resetZoom();
                      });
                    },
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
              ),
            // Right arrow
            if (_currentIndex < widget.fileUrls.length - 1)
              Positioned(
                right: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _currentIndex++;
                        _resetZoom();
                      });
                    },
                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 32),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// Widget để preview file (PDF, DOC, etc.) trong dialog
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
  WebViewController? _controller; // For Mobile (iOS/Android)
  webview_win.WebviewController? _windowsController; // For Windows Desktop
  String? _googleDocsUrl; // Store Google Docs Viewer URL
  String? _iframeViewType;
  String _iframeKey = ''; // Unique key for iframe to force reload
  final FocusNode _focusNode = FocusNode(); // For keyboard/mouse events

  String _getPreviewUrl(String url) {
    final urlLower = url.toLowerCase();
    final encodedUrl = Uri.encodeComponent(url);
    
    // PDF: Sử dụng Google Docs Viewer
    if (urlLower.contains('.pdf')) {
      return 'https://docs.google.com/viewer?url=$encodedUrl&embedded=true';
    }
    
    // DOCX: Kiểm tra DOCX trước (vì DOCX chứa cả ".doc" trong tên)
    if (urlLower.contains('.docx')) {
      return 'https://docs.google.com/gview?embedded=true&url=$encodedUrl';
    }
    
    // DOC: Kiểm tra DOC sau DOCX
    if (urlLower.contains('.doc') && !urlLower.contains('.docx')) {
      return 'https://docs.google.com/gview?embedded=true&url=$encodedUrl';
    }
    
    // PNG/JPG/JPEG: Hiển thị trực tiếp (đã được xử lý riêng với InteractiveViewer)
    if (urlLower.contains('.png') || urlLower.contains('.jpg') || urlLower.contains('.jpeg')) {
      return url;
    }
    
    // Các file khác: Thử Google Docs Viewer
    return 'https://docs.google.com/viewer?url=$encodedUrl&embedded=true';
  }
  
  bool _isDocxFile(String url) {
    final urlLower = url.toLowerCase();
    final fileName = widget.fileName.toLowerCase();
    // Kiểm tra cả trong URL và tên file
    return urlLower.contains('.docx') || fileName.endsWith('.docx');
  }

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

  void _initializeWebView() {
    final String fileUrl = widget.fileUrl;

    if (fileUrl.isNotEmpty && (fileUrl.startsWith('http://') || fileUrl.startsWith('https://'))) {
      // IMPORTANT: Firebase URLs have query params (?alt=media&token=...)
      // Must encode entire URL to preserve these params in viewer
      final encodedUrl = Uri.encodeComponent(fileUrl);

      // Use Google Docs Viewer for Office documents and PDFs
      _googleDocsUrl = _getPreviewUrl(fileUrl);
      
      // Debug: Log preview URL for DOCX files
      if (_isDocxFile(fileUrl)) {
        print('📄 DOCX Preview URL: $_googleDocsUrl');
        print('📄 Original URL: $fileUrl');
      }

      // Generate unique key for iframe to force reload on file change
      _iframeKey = 'file-preview-${widget.fileName}-${DateTime.now().millisecondsSinceEpoch}';

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

      // For Desktop (Windows/Mac/Linux): Use webview_windows for Windows
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
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading file: ${error.description}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(_googleDocsUrl!));
    } else {
      // No valid URL
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
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
          _hasError = true;
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


  @override
  Widget build(BuildContext context) {
    final isDocx = _isDocxFile(widget.fileUrl);
    final isDoc = widget.fileUrl.toLowerCase().contains('.doc') && !isDocx;
    
    // Error state
    if (_hasError) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[900],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  (isDocx || isDoc) ? Icons.description : Icons.error_outline,
                  size: 64,
                  color: (isDocx || isDoc) ? Colors.blue : Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  (isDocx || isDoc)
                      ? 'Không thể preview file DOC/DOCX'
                      : 'Không thể xem preview file này',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    widget.fileName,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    (isDocx || isDoc)
                        ? 'File DOC/DOCX không thể preview.\nFile có thể không được công khai (public)\nhoặc URL không hợp lệ.\n\nVui lòng:\n1. Cấu hình CORS cho Firebase Storage\n2. Hoặc tải file về để xem.'
                        : 'File có thể không được công khai (public)\nhoặc định dạng không được hỗ trợ preview.\nVui lòng kiểm tra cấu hình Firebase Storage.',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final uri = Uri.parse(widget.fileUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Không thể mở file: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Tải file về'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Đóng'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // WEB PLATFORM: Use iframe with Google Docs Viewer
    if (kIsWeb && _googleDocsUrl != null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[900],
        child: Stack(
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
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      });

                      // Handle error events
                      iframe.onError.listen((error) {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                            _hasError = true;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error loading document. Please try again.'),
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
        ),
      );
    }

    // MOBILE PLATFORMS: Use WebView with Google Docs Viewer
    if (_controller != null && _googleDocsUrl != null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[900],
        child: Stack(
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
        ),
      );
    }

    // WINDOWS DESKTOP: Use webview_windows with enhanced scroll support
    if (_windowsController != null && Platform.isWindows && _googleDocsUrl != null) {
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
              _windowsController!.executeScript('window.scrollBy(0, -window.innerHeight);');
            } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
              _windowsController!.executeScript('window.scrollBy(0, window.innerHeight);');
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
    if ((Platform.isMacOS || Platform.isLinux) && _googleDocsUrl != null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[900],
        child: Center(
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
                  'This file will be opened using Google Docs Viewer in your default browser.',
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
                        widget.fileUrl.toLowerCase().contains('.pdf')
                            ? Icons.picture_as_pdf
                            : Icons.description,
                        color: widget.fileUrl.toLowerCase().contains('.pdf')
                            ? Colors.red
                            : Colors.blue,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.fileName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
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
        ),
      );
    }

    // Fallback - loading or no URL
    return Container(
      width: double.infinity,
      height: double.infinity,
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



