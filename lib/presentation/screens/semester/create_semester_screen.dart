// ========================================
// FILE: create_semester_screen.dart
// MÔ TẢ: UI Demo để test hệ thống Template Pattern
// ========================================

import 'package:flutter/material.dart';
import '../../../application/controllers/semester/semester_controller.dart';
import '../../../application/controllers/semester/semester_template_controller.dart';
import '../../../domain/models/semester_template_model.dart';

class CreateSemesterScreen extends StatefulWidget {
  const CreateSemesterScreen({super.key});

  @override
  State<CreateSemesterScreen> createState() => _CreateSemesterScreenState();
}

class _CreateSemesterScreenState extends State<CreateSemesterScreen> {
  final _semesterController = SemesterController();
  final _templateController = SemesterTemplateController();
  
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  
  String? _selectedTemplateId;
  List<SemesterTemplateModel> _templates = [];
  Map<String, dynamic>? _previewInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _yearController.text = DateTime.now().year.toString();
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await _templateController.getTemplatesForDropdown();
      setState(() {
        _templates = templates;
      });
    } catch (e) {
      _showError('Lỗi tải templates: $e');
    }
  }

  Future<void> _updatePreview() async {
    if (_selectedTemplateId == null || _yearController.text.isEmpty) {
      setState(() => _previewInfo = null);
      return;
    }

    try {
      final year = int.tryParse(_yearController.text);
      if (year == null) return;

      final info = await _templateController.getTemplateDisplayInfo(
        templateId: _selectedTemplateId!,
        year: year,
      );

      setState(() => _previewInfo = info);
    } catch (e) {
      print('Error updating preview: $e');
    }
  }

  Future<void> _createSemester() async {
    if (_selectedTemplateId == null || 
        _nameController.text.isEmpty || 
        _yearController.text.isEmpty) {
      _showError('Vui lòng điền đầy đủ thông tin');
      return;
    }

    final year = int.tryParse(_yearController.text);
    if (year == null) {
      _showError('Năm không hợp lệ');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔥 Gọi hàm quan trọng nhất - 4-step process
      final semesterId = await _semesterController.handleCreateSemester(
        templateId: _selectedTemplateId!,
        year: year,
        name: _nameController.text,
      );

      _showSuccess('✅ Tạo thành công semester với ID: $semesterId');
      _clearForm();
    } catch (e) {
      _showError('❌ Lỗi tạo semester: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _yearController.text = DateTime.now().year.toString();
    setState(() {
      _selectedTemplateId = null;
      _previewInfo = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏗️ Tạo Học Kỳ - Template Pattern'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown chọn Template
            DropdownButtonFormField<String>(
              value: _selectedTemplateId,
              decoration: const InputDecoration(
                labelText: '🎯 Chọn Mã HK (Template)',
                border: OutlineInputBorder(),
              ),
              items: _templates.map((template) {
                return DropdownMenuItem(
                  value: template.id,
                  child: Text('${template.id} - ${template.name}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedTemplateId = value);
                _updatePreview();
              },
            ),

            const SizedBox(height: 16),

            // Input năm
            TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: '📅 Năm',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _updatePreview(),
            ),

            const SizedBox(height: 16),

            // Input tên
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '📝 Tên Học Kỳ',
                hintText: 'VD: Học kỳ 1 (2025-2026)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Preview Section
            if (_previewInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔍 PREVIEW:', 
                      style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Mã: ${_previewInfo!['code']}'),
                    Text('Tên mẫu: ${_previewInfo!['name']}'),
                    Text('Bắt đầu: ${_previewInfo!['startDate']}'),
                    Text('Kết thúc: ${_previewInfo!['endDate']}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Create Button
            ElevatedButton(
              onPressed: _isLoading ? null : _createSemester,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('🔥 TẠO HỌC KỲ (4-Step Process)', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 24),

            // Documentation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📋 QUY TẮC 4 BƯỚC:', 
                    style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('1️⃣ Nhận Input từ UI'),
                  Text('2️⃣ Tra cứu Template + Tạo Code'),
                  Text('3️⃣ Tính toán Ngày tuyệt đối'),
                  Text('4️⃣ Lưu Snapshot đầy đủ vào DB'),
                  SizedBox(height: 8),
                  Text('⚠️ KHÔNG ĐƯỢC làm tắt!',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    super.dispose();
  }
}