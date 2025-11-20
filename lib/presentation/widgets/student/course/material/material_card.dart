// Material card widget
import 'package:flutter/material.dart' hide MaterialType;
import 'package:elearning_management_app/domain/models/material_model.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';

class MaterialCard extends StatelessWidget {
  final MaterialModel material;
  final VoidCallback? onTap;
  
  const MaterialCard({
    super.key, 
    required this.material,
    this.onTap,
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
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor();
    final iconBg = iconColor.withOpacity(0.12);
    
    return InkWell(
      onTap: onTap,
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
                      if (material.description != null && material.description!.isNotEmpty)
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
                        )
                      else
                        Text(
                          material.type.displayName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
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
