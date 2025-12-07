import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/domain/models/submission_model.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/upload_file_assignment.dart';
import 'package:elearning_management_app/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/file_preview_overlay.dart';

/// Service for student assignment file upload with format validation
class StudentUploadService {
  /// Pick files with format validation
  static Future<List<UploadedFileModel>> pickFilesForAssignment({
    required Assignment assignment,
    required BuildContext context,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final List<UploadedFileModel> validFiles = [];
      final List<String> invalidFiles = [];

      for (final file in result.files) {
        final extension = file.extension != null ? '.${file.extension}' : '';

        // Validate file format against allowed formats
        if (!_isFormatAllowed(extension, assignment.allowedFileFormats)) {
          invalidFiles.add(file.name);
          continue;
        }

        // Validate file size
        if (assignment.maxFileSizeMB != null) {
          final maxSizeBytes = assignment.maxFileSizeMB! * 1024 * 1024;
          if (file.size > maxSizeBytes) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'File "${file.name}" exceeds maximum size of ${assignment.maxFileSizeMB} MB',
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            continue;
          }
        }

        validFiles.add(
          UploadedFileModel(
            fileName: file.name,
            filePath: kIsWeb ? '' : (file.path ?? ''),
            fileSizeBytes: file.size,
            fileExtension: extension,
            fileBytes: file.bytes,
            platformFile: file,
          ),
        );
      }

      // Show error for invalid formats
      if (invalidFiles.isNotEmpty && context.mounted) {
        final allowedFormatsStr = assignment.allowedFileFormats.join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid file format${invalidFiles.length > 1 ? 's' : ''}: ${invalidFiles.join(', ')}\n'
              'Allowed formats: $allowedFormatsStr\n'
              'Please select files with the correct format.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      return validFiles;
    } catch (e) {
      print('Error picking files: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
  }

  /// Check if file format is allowed
  static bool _isFormatAllowed(String extension, List<String> allowedFormats) {
    if (allowedFormats.isEmpty) return true; // No restrictions

    final normalizedExtension = extension.toLowerCase();
    return allowedFormats.any(
      (format) => format.toLowerCase() == normalizedExtension,
    );
  }

  /// Upload file to Firebase Storage under submissions folder
  /// Uses the same efficient upload method as instructor
  static Future<UploadedFileModel> uploadSubmissionFile({
    required UploadedFileModel file,
    required String assignmentId,
    required String studentId,
    required Function(double progress) onProgress,
  }) async {
    // Delegate to FileUploadService.uploadFileImmediately
    // but use submissions/{assignmentId}/{studentId} path
    return await FileUploadService.uploadFileImmediately(
      file: file,
      courseId: '$assignmentId/$studentId', // Create nested path
      folderName: 'submissions', // Use submissions folder
      onProgress: onProgress,
    );
  }

  /// Get content type from file extension
  /// Delegates to FileUploadService for consistency
  static String getContentType(String extension) {
    return FileUploadService.getContentType(extension);
  }

  /// Delete file from Firebase Storage
  /// filePath should be the full Firebase Storage URL
  static Future<void> deleteFile(String filePath) async {
    try {
      // Use refFromURL to get reference directly from URL
      final storageRef = FirebaseStorage.instance.refFromURL(filePath);
      await storageRef.delete();
      
      print('✅ Deleted file from storage: ${storageRef.fullPath}');
    } catch (e) {
      print('❌ Error deleting file: $e');
      rethrow;
    }
  }

  /// Upload multiple files with progress dialog
  static Future<List<AttachmentModel>> uploadMultipleFilesWithProgress({
    required BuildContext context,
    required List<UploadedFileModel> files,
    required String assignmentId,
    required String studentId,
  }) async {
    final uploadedAttachments = <AttachmentModel>[];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final progressNotifier = ValueNotifier<double>(0.0);

      // Show progress dialog with ValueListenableBuilder
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => ValueListenableBuilder<double>(
            valueListenable: progressNotifier,
            builder: (context, progress, child) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1F2937),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.blue),
                    const SizedBox(height: 20),
                    Text(
                      'Uploading file ${i + 1} of ${files.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      file.fileName,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[800],
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }

      try {
        // Upload file with progress callback
        final uploadedFile = await uploadSubmissionFile(
          file: file,
          assignmentId: assignmentId,
          studentId: studentId,
          onProgress: (progress) {
            // Update progress using SchedulerBinding for thread safety
            SchedulerBinding.instance.addPostFrameCallback((_) {
              progressNotifier.value = progress;
            });
          },
        );

        // Close progress dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Dispose notifier
        progressNotifier.dispose();

        // Add to result list
        uploadedAttachments.add(AttachmentModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: uploadedFile.fileName,
          url: uploadedFile.filePath,
          mimeType: getContentType(uploadedFile.fileExtension),
          sizeInBytes: uploadedFile.fileSizeBytes,
          uploadedAt: DateTime.now(),
        ));

        print('✅ Uploaded ${i + 1}/${files.length}: ${uploadedFile.fileName}');
      } catch (e) {
        // Close progress dialog
        if (context.mounted) {
          Navigator.of(context).pop();
          progressNotifier.dispose();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload ${file.fileName}: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        throw Exception('Upload failed for ${file.fileName}: $e');
      }
    }

    return uploadedAttachments;
  }

  /// Delete file from Firebase Storage
  static Future<void> deleteSubmissionFile(String downloadUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(downloadUrl);
      await ref.delete();
      print('✅ Submission file deleted: ${ref.fullPath}');
    } catch (e) {
      print('❌ Error deleting submission file: $e');
      rethrow;
    }
  }
}

/// Widget to display uploaded files with preview support
class UploadedFilesList extends StatelessWidget {
  final List<UploadedFileModel> files;
  final Function(int index)? onRemove;
  final bool showPreview;

  const UploadedFilesList({
    super.key,
    required this.files,
    this.onRemove,
    this.showPreview = true,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uploaded Files (${files.length})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...files.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildFileCard(context, file, index),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFileCard(
      BuildContext context, UploadedFileModel file, int index) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: InkWell(
        onTap: showPreview && _canPreview(file)
            ? () {
                FilePreviewOverlay.show(context, files, initialIndex: index);
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // File icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FileUploadService.getFileColor(file.fileExtension)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  FileUploadService.getFileIcon(file.fileExtension),
                  color: FileUploadService.getFileColor(file.fileExtension),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.fileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
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

              // Preview/Remove buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showPreview && _canPreview(file))
                    IconButton(
                      onPressed: () {
                        FilePreviewOverlay.show(context, files,
                            initialIndex: index);
                      },
                      icon: Icon(Icons.visibility, color: Colors.blue[400]),
                      tooltip: 'Preview',
                      iconSize: 20,
                    ),
                  if (onRemove != null)
                    IconButton(
                      onPressed: () => onRemove!(index),
                      icon: Icon(Icons.close, color: Colors.red[400]),
                      tooltip: 'Remove',
                      iconSize: 20,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canPreview(UploadedFileModel file) {
    // Can preview: images, PDFs, text files, office files
    return file.isImage ||
        file.isPdf ||
        file.isText ||
        FileUploadService.isOfficeFile(file.fileExtension);
  }
}

/// Upload progress dialog
class UploadProgressDialog extends StatefulWidget {
  final String fileName;
  final ValueNotifier<double> progressNotifier;

  const UploadProgressDialog({
    super.key,
    required this.fileName,
    required this.progressNotifier,
  });

  static Future<void> show(
    BuildContext context, {
    required String fileName,
    required ValueNotifier<double> progressNotifier,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UploadProgressDialog(
        fileName: fileName,
        progressNotifier: progressNotifier,
      ),
    );
  }

  @override
  State<UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.progressNotifier,
      builder: (context, progress, child) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              Text(
                'Uploading...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.fileName,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[800],
                color: Colors.blue,
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
