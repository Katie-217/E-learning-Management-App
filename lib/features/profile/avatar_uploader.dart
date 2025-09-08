import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AvatarUploader extends StatefulWidget {
  const AvatarUploader({super.key});

  @override
  State<AvatarUploader> createState() => _AvatarUploaderState();
}

class _AvatarUploaderState extends State<AvatarUploader> {
  String? _fileName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_fileName != null) Text('Selected: $_fileName'),
        FilledButton(
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles(type: FileType.image);
            if (result != null && result.files.isNotEmpty) {
              setState(() => _fileName = result.files.single.name);
            }
          },
          child: const Text('Choose Avatar'),
        ),
      ],
    );
  }
}















