// ========================================
// FILE: file_upload_service.dart
// DESCRIPTION: Service for handling file uploads to Firebase Storage
// ========================================

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;

class FileUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Pick files using file_picker
  Future<List<PlatformFile>?> pickFiles({
    bool allowMultiple = true,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: type,
        allowedExtensions: allowedExtensions,
      );

      return result?.files;
    } catch (e) {
      throw Exception('Không thể chọn file: $e');
    }
  }

  /// Upload single file to Firebase Storage
  Future<String> uploadFile({
    required PlatformFile file,
    required String folder, // e.g., 'forum_attachments'
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final ref = _storage.ref().child('$folder/$fileName');

      UploadTask uploadTask;
      
      if (kIsWeb) {
        // Web: upload from bytes
        if (file.bytes != null) {
          uploadTask = ref.putData(file.bytes!);
        } else {
          throw Exception('File không có dữ liệu');
        }
      } else {
        // Mobile/Desktop: upload from file path
        if (file.path != null) {
          uploadTask = ref.putFile(File(file.path!));
        } else {
          throw Exception('File không có đường dẫn');
        }
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Không thể upload file: $e');
    }
  }

  /// Upload multiple files
  Future<List<String>> uploadMultipleFiles({
    required List<PlatformFile> files,
    required String folder,
  }) async {
    final List<String> urls = [];
    
    for (var file in files) {
      try {
        final url = await uploadFile(file: file, folder: folder);
        urls.add(url);
      } catch (e) {
        // Continue uploading other files even if one fails
        print('Lỗi upload file ${file.name}: $e');
      }
    }
    
    return urls;
  }

  /// Delete file from Firebase Storage by URL
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Không thể xóa file: $e');
    }
  }

  /// Get file extension from filename
  String getFileExtension(String filename) {
    return path.extension(filename).toLowerCase();
  }

  /// Check if file is an image
  bool isImageFile(String filename) {
    final ext = getFileExtension(filename);
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext);
  }

  /// Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}