// create_course_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/semester_model.dart';

class CreateCourseScreen extends ConsumerStatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  ConsumerState<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends ConsumerState<CreateCourseScreen> {
  // Step control
  int _currentStep = 0; // 0: Select Semester, 1: Create Course, 2: Create Groups
  
  // Form controllers
  late TextEditingController _courseCodeController;
  late TextEditingController _courseNameController;
  late TextEditingController _groupNameController;
  
  String? _selectedSemesterId;
  int _selectedSessions = 10; // 10 or 15
  List<String> _groups = []; // Danh sách group tạo

  @override
  void initState() {
    super.initState();
    _courseCodeController = TextEditingController();
    _courseNameController = TextEditingController();
    _groupNameController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('➕ Tạo Khóa Học'),
        backgroundColor: Colors.blue[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            _buildStepIndicator(),
            const SizedBox(height: 24),
            
            // Step content
            if (_currentStep == 0) _buildStepSelectSemester(),
            if (_currentStep == 1) _buildStepCreateCourse(),
            if (_currentStep == 2) _buildStepCreateGroups(),
            
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // ========== STEP 1: Chọn Semester ==========
  Widget _buildStepSelectSemester() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1️⃣ Chọn Học Kỳ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Dropdown chọn semester
        FutureBuilder<List<SemesterModel>>(
          future: _getSemesters(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('❌ Không có học kỳ nào');
            }

            return DropdownButtonFormField<String>(
              value: _selectedSemesterId,
              decoration: const InputDecoration(
                labelText: 'Học Kỳ',
                border: OutlineInputBorder(),
              ),
              items: snapshot.data!.map((semester) {
                return DropdownMenuItem(
                  value: semester.id,
                  child: Text(semester.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedSemesterId = value);
              },
              validator: (value) => value == null ? 'Vui lòng chọn học kỳ' : null,
            );
          },
        ),
      ],
    );
  }

  // ========== STEP 2: Tạo Course ==========
  Widget _buildStepCreateCourse() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2️⃣ Tạo Khóa Học',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Course Code
        TextFormField(
          controller: _courseCodeController,
          decoration: const InputDecoration(
            labelText: 'Mã Khóa Học',
            hintText: 'VD: CS101',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? 'Vui lòng nhập mã khóa' : null,
        ),
        const SizedBox(height: 12),
        
        // Course Name
        TextFormField(
          controller: _courseNameController,
          decoration: const InputDecoration(
            labelText: 'Tên Khóa Học',
            hintText: 'VD: Lập trình Web',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên khóa' : null,
        ),
        const SizedBox(height: 12),
        
        // Sessions dropdown (10 or 15)
        DropdownButtonFormField<int>(
          value: _selectedSessions,
          decoration: const InputDecoration(
            labelText: 'Số Buổi Học',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 10, child: Text('10 buổi')),
            DropdownMenuItem(value: 15, child: Text('15 buổi')),
          ],
          onChanged: (value) {
            setState(() => _selectedSessions = value ?? 10);
          },
        ),
      ],
    );
  }

  // ========== STEP 3: Tạo Groups ==========
  Widget _buildStepCreateGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3️⃣ Tạo Nhóm',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Input tên group mới
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên Nhóm',
                  hintText: 'VD: Nhóm 1',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _addGroup,
              icon: const Icon(Icons.add),
              label: const Text('Thêm'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Danh sách groups
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _groups.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('📭 Chưa thêm nhóm nào'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_groups[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => _groups.removeAt(index));
                        },
                      ),
                    );
                  },
                ),
        ),
        
        const SizedBox(height: 8),
        Text(
          'ℹ️ Tạo ít nhất 1 nhóm',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  // ========== Helper Methods ==========
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStepBadge('1', 'Semester', _currentStep >= 0),
        _buildStepBadge('2', 'Course', _currentStep >= 1),
        _buildStepBadge('3', 'Groups', _currentStep >= 2),
      ],
    );
  }

  Widget _buildStepBadge(String num, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              num,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() => _currentStep--);
              },
              child: const Text('⬅️ Quay Lại'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _currentStep < 2
                ? () {
                    if (_validateCurrentStep()) {
                      setState(() => _currentStep++);
                    }
                  }
                : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentStep < 2 ? Colors.blue : Colors.green,
            ),
            child: Text(
              _currentStep < 2 ? '➡️ Tiếp Tục' : '✅ Hoàn Thành',
            ),
          ),
        ),
      ],
    );
  }

  void _addGroup() {
    if (_groupNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Vui lòng nhập tên nhóm')),
      );
      return;
    }

    setState(() {
      _groups.add(_groupNameController.text);
      _groupNameController.clear();
    });
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0 && _selectedSemesterId == null) {
      _showError('Vui lòng chọn học kỳ');
      return false;
    }
    if (_currentStep == 1) {
      if (_courseCodeController.text.isEmpty) {
        _showError('Vui lòng nhập mã khóa');
        return false;
      }
      if (_courseNameController.text.isEmpty) {
        _showError('Vui lòng nhập tên khóa');
        return false;
      }
    }
    if (_currentStep == 2 && _groups.isEmpty) {
      _showError('Vui lòng tạo ít nhất 1 nhóm');
      return false;
    }
    return true;
  }

  Future<void> _submitForm() async {
    // TODO: Lưu Course + Groups vào Firebase
    print('✅ Tạo course: ${_courseNameController.text}');
    print('✅ Groups: $_groups');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Tạo khóa học thành công!')),
    );
    
    Navigator.pop(context);
  }

  Future<void> _showError(String msg) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Lỗi'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<List<SemesterModel>> _getSemesters() async {
    // TODO: Gọi API/Repository
    return [];
  }

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseNameController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }
}