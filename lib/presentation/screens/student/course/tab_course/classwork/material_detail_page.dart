import 'package:flutter/material.dart' hide MaterialType;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:elearning_management_app/domain/models/material_model.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';

// Web imports disabled for Windows compatibility
// import 'dart:html' as html;

// View widget for material detail (used within same page, no rebuild)
class MaterialDetailView extends StatelessWidget {
  final MaterialModel material;
  final CourseModel course;
  final VoidCallback onBack;

  const MaterialDetailView({
    super.key,
    required this.material,
    required this.course,
    required this.onBack,
  });

  IconData _getIcon() {
    switch (material.type) {
      case MaterialType.document:
        return Icons.description_outlined;
      case MaterialType.presentation:
        return Icons.slideshow_outlined;
      case MaterialType.video:
        return Icons.video_library_outlined;
      case MaterialType.audio:
        return Icons.audiotrack_outlined;
      case MaterialType.link:
        return Icons.link_outlined;
      case MaterialType.ebook:
        return Icons.menu_book_outlined;
      case MaterialType.other:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getIconColor() {
    switch (material.type) {
      case MaterialType.document:
        return Colors.blueAccent;
      case MaterialType.presentation:
        return Colors.orangeAccent;
      case MaterialType.video:
        return Colors.redAccent;
      case MaterialType.audio:
        return Colors.purpleAccent;
      case MaterialType.link:
        return Colors.greenAccent;
      case MaterialType.ebook:
        return Colors.brown;
      case MaterialType.other:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor();
    final iconBg = iconColor.withOpacity(0.12);

    return Container(
      color: AppColors.bgDark,
      child: Column(
        children: [
          // Back button header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.textPrimary),
                  onPressed: onBack,
                  tooltip: 'Back to materials',
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Content Area (Left)
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      material.title,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          material.authorName.isNotEmpty
                                              ? material.authorName
                                              : course.instructor,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          '•',
                                          style: TextStyle(
                                              color: AppColors.textMuted),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatDate(material.createdAt),
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Type badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: iconBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getIcon(),
                                      color: iconColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      material.type.displayName,
                                      style: TextStyle(
                                        color: iconColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 32, color: AppColors.border),

                          // Description Section
                          if (material.description != null &&
                              material.description!.isNotEmpty) ...[
                            Text(
                              material.description!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Attachment/File Section (with embedded link)
                          if (material.attachment != null ||
                              (material.url != null &&
                                  material.url!.isNotEmpty)) ...[
                            const Text(
                              'Attachment',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () async {
                                // Ưu tiên dùng URL từ material.url, nếu không có thì dùng attachment.url
                                String? urlToOpen = material.url?.isNotEmpty ==
                                        true
                                    ? material.url
                                    : (material.attachment?.url.isNotEmpty ==
                                            true
                                        ? material.attachment!.url
                                        : null);

                                if (urlToOpen != null && urlToOpen.isNotEmpty) {
                                  try {
                                    final uri = Uri.parse(urlToOpen);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(
                                        uri,
                                        mode: kIsWeb
                                            ? LaunchMode.externalApplication
                                            : LaunchMode.platformDefault,
                                      );
                                    } else if (kIsWeb) {
                                      // Web platform not fully supported yet
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Web platform opening not supported yet'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    // Show error for all platforms
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error opening URL: $e'),
                                      ),
                                    );
                                  }
                                } else if (material.attachment != null) {
                                  // Nếu không có URL, có thể preview file trực tiếp (nếu có bytes)
                                  // TODO: Implement file preview
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('File preview not available'),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(4),
                                  color: AppColors.surfaceVariant,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: iconBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        _getIcon(),
                                        color: iconColor,
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            material.attachment?.name ??
                                                (material.url != null
                                                    ? Uri.parse(material.url!)
                                                        .pathSegments
                                                        .last
                                                    : 'File'),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (material.attachment != null &&
                                              material.attachment!.sizeInBytes >
                                                  0)
                                            Text(
                                              '${(material.attachment!.sizeInBytes / 1024).toStringAsFixed(1)} KB',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            )
                                          else if (material.url != null)
                                            Text(
                                              'Click to open',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.open_in_new,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Class Comments Section
                          Divider(height: 32, color: AppColors.border),
                          Row(
                            children: [
                              const Text(
                                'Class comments',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  // TODO: Add comment
                                },
                                child: const Text(
                                  'Add comment',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'No comments yet',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Sidebar (Right)
                Container(
                  width: 360,
                  margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Material Details Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDetailItem(
                              'Type',
                              material.type.displayName,
                              _getIcon(),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailItem(
                              'Created',
                              _formatDate(material.createdAt),
                              Icons.calendar_today,
                            ),
                            if (material.updatedAt != null) ...[
                              const SizedBox(height: 12),
                              _buildDetailItem(
                                'Updated',
                                _formatDate(material.updatedAt!),
                                Icons.update,
                              ),
                            ],
                            // ❌ REMOVED: downloadCount - Now tracked via MaterialTrackingModel
                            // TODO: Add MaterialTrackingController to show view/download stats
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Full page version (for navigation if needed)
class MaterialDetailPage extends StatelessWidget {
  final MaterialModel material;
  final CourseModel course;

  const MaterialDetailPage({
    super.key,
    required this.material,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgAppbar,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          course.code,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: MaterialDetailView(
        material: material,
        course: course,
        onBack: () => Navigator.pop(context),
      ),
    );
  }
}
