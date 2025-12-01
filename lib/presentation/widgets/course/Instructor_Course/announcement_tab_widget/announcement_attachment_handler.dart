// ========================================
// FILE: announcement_attachment_handler.dart
// MÔ TẢ: Handler for file attachments in announcements
// ========================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class AnnouncementAttachmentHandler {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // ========================================
  // 1. PICK FILES (Multiple)
  // ========================================
  Future<List<PlatformFile>> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'jpeg', 'png', 'zip'],
      );
      
      if (result != null) {
        return result.files;
      }
      return [];
    } catch (e) {
      debugPrint('Error picking files: $e');
      return [];
    }
  }

  // ========================================
  // 2. UPLOAD FILES TO FIREBASE STORAGE
  // ========================================
  Future<List<Map<String, dynamic>>> uploadFiles({
    required List<PlatformFile> files,
    required String courseId,
    required String announcementId,
    Function(double)? onProgress,
  }) async {
    final List<Map<String, dynamic>> uploadedFiles = [];
    
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      
      try {
        // Create unique file path
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final path = 'announcements/$courseId/$announcementId/$fileName';
        
        // Upload task
        final uploadTask = _storage.ref(path).putData(
          file.bytes!,
          SettableMetadata(contentType: _getMimeType(file.extension ?? '')),
        );
        
        // Track progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (onProgress != null) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress((i + progress) / files.length);
          }
        });
        
        // Wait for completion
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        // Add to result
        uploadedFiles.add({
          'id': _generateFileId(),
          'name': file.name,
          'url': downloadUrl,
          'mimeType': _getMimeType(file.extension ?? ''),
          'sizeInBytes': file.size,
          'uploadedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Error uploading file ${file.name}: $e');
        // Continue with other files
      }
    }
    
    return uploadedFiles;
  }

  // ========================================
  // 3. DELETE FILE FROM STORAGE
  // ========================================
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  // ========================================
  // 4. DOWNLOAD FILE (For tracking)
  // ========================================
  Future<void> downloadFile({
    required String url,
    required String fileName,
  }) async {
    try {
      // For web: trigger browser download
      if (kIsWeb) {
        // Import dart:html for web
        // html.AnchorElement(href: url)
        //   ..setAttribute('download', fileName)
        //   ..click();
      } else {
        // For mobile/desktop: use file_picker to save
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save File',
          fileName: fileName,
        );
        
        if (result != null) {
          // Download and save file
          // Implementation depends on your requirements
        }
      }
    } catch (e) {
      debugPrint('Error downloading file: $e');
    }
  }

  // ========================================
  // HELPER METHODS
  // ========================================
  
  String _getMimeType(String extension) {
    final mimeTypes = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'zip': 'application/zip',
    };
    
    return mimeTypes[extension.toLowerCase()] ?? 'application/octet-stream';
  }
  
  String _generateFileId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

// ========================================
// PROVIDER
// ========================================

final attachmentHandlerProvider = Provider<AnnouncementAttachmentHandler>((ref) {
  return AnnouncementAttachmentHandler();
});