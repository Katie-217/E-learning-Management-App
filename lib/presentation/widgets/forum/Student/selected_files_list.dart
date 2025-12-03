// file: selected_files_list.dart (hoặc đặt chung vào screen)
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/file_upload_service.dart';
class SelectedFilesList extends StatelessWidget {
  final List<PlatformFile> files;
  final Function(int index) onRemove;

  const SelectedFilesList({
    super.key, 
    required this.files, 
    required this.onRemove
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final file = files[index];
          final isImage = ['.jpg', '.png', '.jpeg', '.webp'].any((ext) => 
              file.name.toLowerCase().endsWith(ext));

          return Container(
            width: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF374151),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[700]!),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                    image: (isImage && file.bytes != null) 
                        ? DecorationImage(
                            image: MemoryImage(file.bytes!), 
                            fit: BoxFit.cover
                          )
                        : null,
                  ),
                  child: !isImage 
                      ? const Icon(Icons.insert_drive_file, color: Colors.white70, size: 20)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        file.name,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        FileUploadService().formatFileSize(file.size),
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => onRemove(index),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}