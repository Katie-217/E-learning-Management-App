// ========================================
// FILE: material_controller.dart
// MÔ TẢ: Controller quản lý logic tạo/sửa Material (tách khỏi UI)
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/material_model.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/add_link_assignments.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/upload_file_assignment.dart';

// ========================================
// PROVIDER: MaterialController
// ========================================
final materialControllerProvider =
    StateNotifierProvider<MaterialControllerNotifier, AsyncValue<void>>(
  (ref) => MaterialControllerNotifier(),
);

class MaterialControllerNotifier extends StateNotifier<AsyncValue<void>> {
  MaterialControllerNotifier() : super(const AsyncValue.data(null));

  // Wrapper methods để gọi static methods
  Future<void> deleteMaterial({
    required String materialId,
    required String courseId,
    String? filePath,
  }) async {
    state = const AsyncValue.loading();
    try {
      await MaterialController.deleteMaterial(
        materialId: materialId,
        courseId: courseId,
        filePath: filePath,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

class MaterialController {
  // ========================================
  // HÀM: initializeEditMode
  // MÔ TẢ: Load dữ liệu Material hiện có để edit
  // ========================================
  static Future<Map<String, dynamic>> initializeEditMode(
      MaterialModel material) async {
    final data = <String, dynamic>{
      'title': material.title,
      'description': material.description ?? '',
      'attachedLinks': <LinkMetadata>[],
      'uploadedFiles': <UploadedFileModel>[],
    };

    // Load existing link
    if (material.url != null && material.url!.isNotEmpty) {
      // Nếu có linkMetadata, dùng nó
      if (material.linkMetadata != null) {
        data['attachedLinks'].add(LinkMetadata(
          url: material.linkMetadata!.url,
          title: material.linkMetadata!.title,
          imageUrl: material.linkMetadata!.imageUrl,
          description: material.linkMetadata!.description,
          domain: material.linkMetadata!.domain,
        ));
      } else {
        // Fallback: tạo LinkMetadata từ URL
        data['attachedLinks'].add(LinkMetadata(
          url: material.url!,
          title: material.title,
          imageUrl: null,
          description: material.description,
          domain: Uri.parse(material.url!).host,
        ));
      }
    }

    // Load existing attachment
    if (material.attachment != null) {
      final attachment = material.attachment!;
      data['uploadedFiles'].add(UploadedFileModel(
        fileName: attachment.name,
        filePath: attachment.url,
        fileSizeBytes: attachment.sizeInBytes,
        fileExtension: attachment.name.contains('.')
            ? attachment.name.substring(attachment.name.lastIndexOf('.'))
            : '',
        fileBytes: null,
        platformFile: PlatformFile(
          name: attachment.name,
          size: attachment.sizeInBytes,
          path: attachment.url,
        ),
      ));
    }

    return data;
  }

  // ========================================
  // HÀM: hasUploadingFiles
  // MÔ TẢ: Kiểm tra có file đang upload không
  // ========================================
  static bool hasUploadingFiles(
    List<UploadedFileModel> uploadedFiles,
    Map<String, double> uploadProgress,
  ) {
    for (var file in uploadedFiles) {
      final progress = uploadProgress[file.fileName] ?? 1.0;
      if (progress < 1.0) return true;
    }
    return false;
  }

  // ========================================
  // HÀM: cleanupUploadedFiles
  // MÔ TẢ: Xóa các file đã upload nếu cancel (chỉ ở CREATE mode)
  // ========================================
  static Future<void> cleanupUploadedFiles(
    List<UploadedFileModel> uploadedFiles,
    bool isPublished,
    bool isEditMode,
  ) async {
    try {
      // Không cleanup nếu đã publish hoặc đang edit
      if (isPublished || isEditMode) return;

      final filesToDelete = uploadedFiles
          .where((file) => file.filePath.startsWith('https://'))
          .toList();

      if (filesToDelete.isEmpty) return;

      for (var file in filesToDelete) {
        try {
          await FileUploadService.deleteFileFromFirebase(file.filePath);
          print('🗑️ Cleaned up file: ${file.fileName}');
        } catch (e) {
          print('⚠️ Failed to delete ${file.fileName}: $e');
        }
      }
    } catch (e) {
      print('❌ Error during cleanup: $e');
    }
  }

  // ========================================
  // HÀM: publishMaterial
  // MÔ TẢ: Save Material vào Firestore (Create hoặc Update)
  // ========================================
  static Future<void> publishMaterial({
    required String courseId,
    required String title,
    required String description,
    required List<LinkMetadata> attachedLinks,
    required List<UploadedFileModel> uploadedFiles,
    MaterialModel? existingMaterial,
  }) async {
    // Validate inputs
    if (title.trim().isEmpty) {
      throw Exception('Title is required');
    }

    if (uploadedFiles.isEmpty && attachedLinks.isEmpty) {
      throw Exception('Please add at least one file or link to the material');
    }

    if (courseId.isEmpty) {
      throw Exception('No course ID available');
    }

    // Get current user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    // Prepare attachment data
    AttachmentModel? attachment;
    if (uploadedFiles.isNotEmpty) {
      final file = uploadedFiles.first;
      attachment = AttachmentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: file.fileName,
        url: file.filePath,
        mimeType: file.fileExtension,
        sizeInBytes: file.fileSizeBytes,
        uploadedAt: DateTime.now(),
      );
    }

    // Prepare link data
    String? linkUrl;
    Map<String, dynamic>? linkMetadataMap;
    if (attachedLinks.isNotEmpty) {
      final linkMeta = attachedLinks.first;
      linkUrl = linkMeta.url;
      // Save full link metadata for preview
      linkMetadataMap = {
        'url': linkMeta.url,
        'title': linkMeta.title,
        'imageUrl': linkMeta.imageUrl,
        'description': linkMeta.description,
        'domain': linkMeta.domain,
      };
    }

    // Prepare Firestore data
    final materialData = {
      'courseId': courseId,
      'title': title.trim(),
      'description': description.trim(),
      'url': linkUrl,
      'linkMetadata': linkMetadataMap,
      'filePath':
          uploadedFiles.isNotEmpty ? uploadedFiles.first.filePath : null,
      'attachment': attachment != null
          ? {
              'id': attachment.id,
              'name': attachment.name,
              'url': attachment.url,
              'mimeType': attachment.mimeType,
              'sizeInBytes': attachment.sizeInBytes,
              'uploadedAt': attachment.uploadedAt.toIso8601String(),
            }
          : null,
      'authorId': currentUser.uid,
      'authorName': currentUser.displayName ?? currentUser.email ?? 'Unknown',
      'isPublished': true,
      'createdAt':
          existingMaterial == null ? FieldValue.serverTimestamp() : null,
      'updatedAt':
          existingMaterial != null ? FieldValue.serverTimestamp() : null,
    };

    // Remove null values
    materialData.removeWhere((key, value) => value == null);

    // Save to Firestore
    final firestore = FirebaseFirestore.instance;
    final materialsRef = firestore
        .collection('course_of_study')
        .doc(courseId)
        .collection('materials');

    if (existingMaterial != null) {
      // Update existing material
      await materialsRef.doc(existingMaterial.id).update(materialData);
      print('✅ Material updated: ${existingMaterial.id}');
    } else {
      // Create new material
      final docRef = await materialsRef.add(materialData);
      print('✅ Material created: ${docRef.id}');
    }
  }

  // ========================================
  // HÀM: uploadFile
  // MÔ TẢ: Upload file lên Firebase Storage với progress callback
  // ========================================
  static Future<UploadedFileModel> uploadFile({
    required UploadedFileModel file,
    required String courseId,
    required Function(double) onProgress,
  }) async {
    return await FileUploadService.uploadFileImmediately(
      file: file,
      courseId: courseId,
      onProgress: onProgress,
      folderName: 'materials', // Material files → 'materials' folder
    );
  }

  // ========================================
  // HÀM: pickFiles
  // MÔ TẢ: Mở file picker để chọn files
  // ========================================
  static Future<List<UploadedFileModel>> pickFiles() async {
    return await FileUploadService.pickFiles();
  }

  // ========================================
  // HÀM: deleteFile
  // MÔ TẢ: Xóa file khỏi Firebase Storage
  // ========================================
  static Future<void> deleteFile(String filePath) async {
    if (filePath.startsWith('https://')) {
      await FileUploadService.deleteFileFromFirebase(filePath);
    }
  }

  // ========================================
  // HÀM: deleteMaterial
  // MÔ TẢ: Xóa Material và các file liên quan khỏi Firestore + Storage
  // ========================================
  static Future<void> deleteMaterial({
    required String materialId,
    required String courseId,
    String? filePath,
  }) async {
    try {
      print('🗑️ Deleting material: $materialId');

      // 1. Delete file from Storage (nếu có)
      if (filePath != null && filePath.isNotEmpty) {
        try {
          await FileUploadService.deleteFileFromFirebase(filePath);
          print('✅ Deleted file from Storage: $filePath');
        } catch (e) {
          print('⚠️ Failed to delete file from Storage: $e');
          // Continue anyway - xóa document quan trọng hơn
        }
      }

      // 2. Delete Material document from Firestore
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('course_of_study')
          .doc(courseId)
          .collection('materials')
          .doc(materialId)
          .delete();

      print('✅ Material deleted successfully: $materialId');
    } catch (e) {
      print('❌ Error deleting material: $e');
      throw Exception('Failed to delete material: $e');
    }
  }
}
