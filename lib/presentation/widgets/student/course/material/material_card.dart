// Material card widget
import 'package:flutter/material.dart';
import 'package:elearning_management_app/domain/models/material_model.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';
import 'package:elearning_management_app/presentation/widgets/student/course/material/material_detail.dart';

class MaterialCard extends StatelessWidget {
  final MaterialModel material;
  final VoidCallback? onTap;
  final bool enableNavigation;

  const MaterialCard({
    super.key,
    required this.material,
    this.onTap,
    this.enableNavigation = true, // ✅ Changed to true by default
  });

  IconData _getIcon() {
    // Quyết định icon dựa vào có file hay link
    final hasAttachment = material.attachment != null;
    final hasUrl = material.url != null && material.url!.isNotEmpty;

    if (hasUrl) {
      return Icons.link_outlined; // Link icon
    } else if (hasAttachment) {
      return Icons.description_outlined; // File icon
    } else {
      return Icons.folder_outlined; // Default
    }
  }

  Color _getIconColor() {
    final hasUrl = material.url != null && material.url!.isNotEmpty;

    if (hasUrl) {
      return Colors.greenAccent; // Link màu xanh lá
    } else {
      return Colors.blueAccent; // File màu blue
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

  void _handleTap(BuildContext context) {
    // Priority 1: Custom onTap callback
    if (onTap != null) {
      onTap!();
    }
    // Priority 2: Navigate to detail page (if enableNavigation is true)
    else if (enableNavigation) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StudentMaterialDetail(
            material: material,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor();
    final iconBg = iconColor.withOpacity(0.12);

    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon với màu theo type
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(),
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    material.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Description or type
                  Row(
                    children: [
                      if (material.description != null &&
                          material.description!.isNotEmpty)
                        Expanded(
                          child: Text(
                            material.description!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(material.createdAt),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Author
                  if (material.authorName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'By ${material.authorName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Arrow icon
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
