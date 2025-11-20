import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../application/controllers/student/student_controller.dart';
import '../../../data/repositories/auth/auth_repository.dart';

class CreateStudentPage extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;
  
  const CreateStudentPage({
    super.key,
    this.onSuccess,
    this.onCancel,
  });

  @override
  State<CreateStudentPage> createState() => _CreateStudentPageState();
}

class _CreateStudentPageState extends State<CreateStudentPage> {
  late StudentController _studentController;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Form Controllers - REMOVED department
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _studentController = StudentController(
      authRepository: AuthRepository.defaultClient(),
    );
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      _showError('❌ Invalid email');
      return false;
    }

    if (_passwordController.text.length < 6) {
      _showError('❌ Password must be at least 6 characters');
      return false;
    }

    if (_studentCodeController.text.trim().isEmpty) {
      _showError('❌ Please enter student code');
      return false;
    }

    return true;
  }

  bool _isValidEmail(String email) {
    return email.contains('@');
  }

  Future<void> _createStudent() async {
    if (!_validateForm()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      print('DEBUG: 🔑 STEP 1 - Create Firebase Auth Account');

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      print('DEBUG: ✅ Firebase Auth Account created successfully: $uid');

      print('DEBUG: 🔑 STEP 2 - Create Student Profile');

      // REMOVED department parameter
      final studentId = await _studentController.createStudent(
        uid: uid,
        email: email,
        name: _nameController.text.trim(),
        studentCode: _studentCodeController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      print('DEBUG: ✅ Student Profile created successfully: $studentId');

      if (mounted) {
        _showSuccess(
          '✅ Student created successfully!\n'
          'UID: $uid\n'
          'Email: $email',
        );

        await Future.delayed(const Duration(seconds: 1));
        if (mounted && widget.onSuccess != null) {
          widget.onSuccess!();
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = '❌ Account creation error:';

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage += '\n📧 This email is already in use';
          break;
        case 'invalid-email':
          errorMessage += '\n📧 Invalid email';
          break;
        case 'weak-password':
          errorMessage += '\n🔒 Password is too weak';
          break;
        case 'operation-not-allowed':
          errorMessage += '\n🚫 Account type not allowed';
          break;
        default:
          errorMessage += '\n${e.message}';
      }

      _showError(errorMessage);
    } catch (e) {
      _showError('❌ Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text(
              '🎉 Success!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.onSuccess != null) {
                widget.onSuccess!();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int minLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: obscureText ? 1 : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFF1F2937),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.indigo,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '🔄 Creating student...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: Account Information
                    _buildSection(
                      '🔐 Account Information',
                      [
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'student@example.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter email';
                            }
                            if (!_isValidEmail(value)) {
                              return 'Invalid email';
                            }
                            return null;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: Colors.grey),
                              hintText: 'Enter password (at least 6 characters)',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[700]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1F2937),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    // SECTION 2: Personal Information
                    _buildSection(
                      '👤 Personal Information',
                      [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Student Name',
                          hint: 'E.g.: Nguyen Van A',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter name';
                            }
                            if (value.length < 3) {
                              return 'Name must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _studentCodeController,
                          label: 'Student Code',
                          hint: 'E.g.: SV001',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter student code';
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: 'E.g.: 0123456789',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                                return 'Phone number must have 10 digits';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const Divider(height: 32, color: Colors.grey),

                    // Create student button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _createStudent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.add, size: 24),
                        label: Text(
                          isLoading ? 'Creating...' : 'Create Student',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : _handleCancel,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Colors.red),
                        ),
                        icon: const Icon(Icons.close, size: 24, color: Colors.red),
                        label: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Info box - REMOVED department note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[900]?.withValues(alpha: 0.3),
                        border: Border.all(color: Colors.blue[700]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ℹ️ Note:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Email must be unique\n'
                            '• Password at least 6 characters\n'
                            '• Student code must not duplicate\n'
                            '• Phone number is optional',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _studentCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
