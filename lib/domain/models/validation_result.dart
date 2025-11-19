// ========================================
// FILE: validation_result.dart
// MÔ TẢ: Model cho kết quả validation
// ========================================

class ValidationResult {
  final bool isValid;
  final String? templateError;
  final String? yearError;
  final String? nameError;

  const ValidationResult({
    required this.isValid,
    this.templateError,
    this.yearError,
    this.nameError,
  });

  ValidationResult copyWith({
    bool? isValid,
    String? templateError,
    String? yearError,
    String? nameError,
  }) {
    return ValidationResult(
      isValid: isValid ?? this.isValid,
      templateError: templateError ?? this.templateError,
      yearError: yearError ?? this.yearError,
      nameError: nameError ?? this.nameError,
    );
  }
}
