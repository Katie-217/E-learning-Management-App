// ========================================
// FILE: forum_file_upload_widget.dart
// MÔ TẢ: Widget dùng chung để upload file cho forum (Student và Instructor)
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../application/controllers/forum/forum_provider.dart';

/// Widget để hiển thị danh sách file đã chọn và cho phép xóa
class SelectedFilesListWidget extends StatelessWidget {
  final List<PlatformFile> files;
  final Function(int index) onRemove;

  const SelectedFilesListWidget({
    super.key,
    required this.files,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text(
                files[index].name,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              InkWell(
                onTap: () => onRemove(index),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper class để quản lý file upload cho forum
class ForumFileUploadHelper {
  /// Pick files từ device
  static Future<List<PlatformFile>?> pickFiles({
    required WidgetRef ref,
    bool allowMultiple = true,
    FileType? type,
    List<String>? allowedExtensions,
  }) async {
    final uploadService = ref.read(fileUploadServiceProvider);
    try {
      final files = await uploadService.pickFiles(
        allowMultiple: allowMultiple,
        type: type ?? FileType.any,
        allowedExtensions: allowedExtensions,
      );
      return files;
    } catch (e) {
      print('Error picking files: $e');
      return null;
    }
  }

  /// Upload multiple files lên Firebase Storage
  static Future<List<String>> uploadFiles({
    required WidgetRef ref,
    required List<PlatformFile> files,
    required String folder,
  }) async {
    if (files.isEmpty) return [];

    final uploadService = ref.read(fileUploadServiceProvider);
    try {
      final urls = await uploadService.uploadMultipleFiles(
        files: files,
        folder: folder,
      );
      return urls;
    } catch (e) {
      print('Error uploading files: $e');
      rethrow;
    }
  }
}



