import 'dart:io';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // For SchedulerBinding
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Upload progress model
class UploadProgress {
  final double progress; // 0.0 to 1.0
  final String? downloadUrl;
  final String? error;

  UploadProgress({
    required this.progress,
    this.downloadUrl,
    this.error,
  });

  bool get isComplete => progress >= 1.0 && downloadUrl != null;
  bool get hasError => error != null;
}

/// Model to store uploaded file information
class UploadedFileModel {
  final String fileName;
  final String filePath; // Local path or URL
  final int fileSizeBytes;
  final String fileExtension;
  final Uint8List? fileBytes; // For web platform
  final PlatformFile platformFile; // Keep reference for later use

  UploadedFileModel({
    required this.fileName,
    required this.filePath,
    required this.fileSizeBytes,
    required this.fileExtension,
    this.fileBytes,
    required this.platformFile,
  });

  /// Get formatted file size
  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(fileSizeBytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }

  /// Check if file is an image
  bool get isImage {
    return ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp']
        .contains(fileExtension.toLowerCase());
  }

  /// Check if file is a text file
  bool get isText {
    return ['.txt', '.md', '.json', '.xml', '.csv']
        .contains(fileExtension.toLowerCase());
  }

  /// Check if file is a PDF
  bool get isPdf {
    return fileExtension.toLowerCase() == '.pdf';
  }
}

/// Service to handle file picking and management
class FileUploadService {
  /// Check if file extension is an Office file (.doc, .docx, .xls, .xlsx, .ppt, .pptx)
  static bool isOfficeFile(String extension) {
    const officeExtensions = [
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx'
    ];
    return officeExtensions.contains(extension.toLowerCase());
  }

  /// Pick multiple files from device
  static Future<List<UploadedFileModel>> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true, // Ensure bytes are loaded on web
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      return result.files.map((file) {
        final extension = file.extension != null ? '.${file.extension}' : '';
        return UploadedFileModel(
          fileName: file.name,
          filePath:
              kIsWeb ? '' : (file.path ?? ''), // On web, path is unavailable
          fileSizeBytes: file.size,
          fileExtension: extension,
          fileBytes: file.bytes, // Should have bytes with withData: true
          platformFile: file,
        );
      }).toList();
    } catch (e) {
      print('Error picking files: $e');
      return [];
    }
  }

  /// Upload file to Firebase Storage and return download URL
  /// Returns a Stream of progress (0.0 to 1.0) and final URL
  static Stream<UploadProgress> uploadFileToFirebase({
    required UploadedFileModel file,
    required String courseId,
  }) async* {
    try {
      // Create unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${file.fileName}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('assignments')
          .child(courseId)
          .child(fileName);

      // Determine content type
      final contentType = _getContentType(file.fileExtension);

      // Upload based on platform
      UploadTask uploadTask;
      if (kIsWeb && file.fileBytes != null) {
        // Web: Use bytes
        uploadTask = storageRef.putData(
          file.fileBytes!,
          SettableMetadata(contentType: contentType),
        );
      } else if (file.filePath.isNotEmpty) {
        // Mobile/Desktop: Use file path
        uploadTask = storageRef.putFile(
          File(file.filePath),
          SettableMetadata(contentType: contentType),
        );
      } else {
        throw Exception('No file data available for upload');
      }

      // Listen to upload progress
      await for (final snapshot in uploadTask.snapshotEvents) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;

        // SAFE: Ensure UI updates happen on main thread
        SchedulerBinding.instance.addPostFrameCallback((_) {
          // This callback runs on the main thread
        });

        yield UploadProgress(progress: progress);
      }

      // Get download URL after completion
      final downloadUrl = await uploadTask.snapshot.ref.getDownloadURL();
      yield UploadProgress(progress: 1.0, downloadUrl: downloadUrl);
    } catch (e) {
      yield UploadProgress(progress: 0.0, error: e.toString());
    }
  }

  /// Upload file immediately with callback-based progress
  /// Simplified version for use in CreateAssignmentPage
  static Future<UploadedFileModel> uploadFileImmediately({
    required UploadedFileModel file,
    required String courseId,
    required Function(double progress) onProgress,
    String folderName =
        'assignments', // Default 'assignments' để backward compatible
  }) async {
    try {
      // Create Firebase Storage reference
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${file.fileName}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(folderName) // Sử dụng tham số folderName thay vì hardcode
          .child(courseId)
          .child(fileName);

      // Determine content type
      final contentType = _getContentType(file.fileExtension);

      // Create upload task
      UploadTask uploadTask;
      if (kIsWeb && file.fileBytes != null) {
        uploadTask = storageRef.putData(
          file.fileBytes!,
          SettableMetadata(contentType: contentType),
        );
      } else if (file.filePath.isNotEmpty &&
          !file.filePath.startsWith('http')) {
        uploadTask = storageRef.putFile(
          File(file.filePath),
          SettableMetadata(contentType: contentType),
        );
      } else {
        throw Exception('Invalid file for upload');
      }

      // Listen to progress - SAFE: Wrap callback to ensure main thread execution
      uploadTask.snapshotEvents.listen(
        (snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;

          // Ensure progress callback runs on main thread
          SchedulerBinding.instance.addPostFrameCallback((_) {
            onProgress(progress);
          });
        },
        onError: (error) {
          // Handle error safely on main thread
          SchedulerBinding.instance.addPostFrameCallback((_) {
            print('❌ Upload error (handled safely): $error');
          });
        },
      );

      // Wait for completion - wrapped with try-catch to prevent crashes
      final TaskSnapshot snapshot;
      try {
        snapshot = await uploadTask;
      } catch (e) {
        // If upload fails, throw with context
        throw Exception('Upload failed: $e');
      }

      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Return updated file with Firebase URL
      return UploadedFileModel(
        fileName: file.fileName,
        filePath: downloadUrl,
        fileSizeBytes: file.fileSizeBytes,
        fileExtension: file.fileExtension,
        fileBytes: null, // Clear bytes to save memory
        platformFile: file.platformFile,
      );
    } catch (e) {
      // Catch any errors including threading issues
      print('❌ Upload failed safely (no crash): $e');
      rethrow;
    }
  }

  /// Delete file from Firebase Storage using download URL
  static Future<void> deleteFileFromFirebase(String downloadUrl) async {
    try {
      // Get reference from download URL
      final ref = FirebaseStorage.instance.refFromURL(downloadUrl);

      // Delete the file
      await ref.delete();

      print('✅ File deleted from Firebase Storage: ${ref.fullPath}');
    } catch (e) {
      print('❌ Error deleting file from Firebase Storage: $e');
      rethrow;
    }
  }

  /// Helper: Get content type from file extension
  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.txt':
        return 'text/plain';
      case '.zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get icon for file type
  static IconData getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart;
      case '.ppt':
      case '.pptx':
        return Icons.slideshow;
      case '.zip':
      case '.rar':
      case '.7z':
        return Icons.folder_zip;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
        return Icons.image;
      case '.mp4':
      case '.avi':
      case '.mov':
        return Icons.video_file;
      case '.mp3':
      case '.wav':
        return Icons.audio_file;
      case '.txt':
      case '.md':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Get color for file type
  static Color getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return Colors.red;
      case '.doc':
      case '.docx':
        return Colors.blue;
      case '.xls':
      case '.xlsx':
        return Colors.green;
      case '.ppt':
      case '.pptx':
        return Colors.orange;
      case '.zip':
      case '.rar':
      case '.7z':
        return Colors.purple;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
        return Colors.teal;
      case '.mp4':
      case '.avi':
      case '.mov':
        return Colors.pink;
      case '.mp3':
      case '.wav':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

/// Widget to display uploaded file card (similar to LinkPreviewCard)
class FilePreviewCard extends StatelessWidget {
  final UploadedFileModel file;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const FilePreviewCard({
    super.key,
    required this.file,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Thumbnail or Icon
                _buildThumbnail(),

                // Right: File Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // File Name
                        Text(
                          file.fileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // File Size
                        Text(
                          file.formattedSize,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Remove Button (X) at top-right corner
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    if (file.isImage) {
      // Priority order:
      // 1. Firebase URL (after upload) -> use network (works on ALL platforms)
      // 2. Web + bytes -> use memory
      // 3. Desktop/Mobile + local path -> use file

      if (file.filePath.isNotEmpty &&
          (file.filePath.startsWith('http://') ||
              file.filePath.startsWith('https://'))) {
        // Firebase URL - works on ALL platforms including Web
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          ),
          child: Image.network(
            file.filePath,
            width: 120,
            height: 80,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 120,
                height: 80,
                color: Colors.grey[800],
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildIconThumbnail();
            },
          ),
        );
      } else if (kIsWeb && file.fileBytes != null) {
        // Web with local bytes (before upload)
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          ),
          child: Image.memory(
            file.fileBytes!,
            width: 120,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildIconThumbnail();
            },
          ),
        );
      } else if (!kIsWeb && file.filePath.isNotEmpty) {
        // Desktop/Mobile with local path (NOT Web!)
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          ),
          child: Image.file(
            File(file.filePath),
            width: 120,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildIconThumbnail();
            },
          ),
        );
      }
    }

    return _buildIconThumbnail();
  }

  Widget _buildIconThumbnail() {
    final icon = FileUploadService.getFileIcon(file.fileExtension);
    final color = FileUploadService.getFileColor(file.fileExtension);

    return Container(
      width: 120,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
      ),
      child: Icon(
        icon,
        size: 40,
        color: color,
      ),
    );
  }
}

/// Button to trigger file picker
class UploadFileButton extends StatelessWidget {
  final Function(List<UploadedFileModel>) onFilesSelected;

  const UploadFileButton({super.key, required this.onFilesSelected});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final files = await FileUploadService.pickFiles();
        if (files.isNotEmpty) {
          onFilesSelected(files);
        }
      },
      icon: const Icon(Icons.upload_file, size: 18),
      label: const Text('Upload Files'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[800]!),
        ),
      ),
    );
  }
}
