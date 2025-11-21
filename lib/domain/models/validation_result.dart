// ========================================
// FILE: validation_result.dart
// PURPOSE: Model for validation results from business logic
// Clean Architecture: Domain Layer
// ========================================

class ValidationResult {
  final bool isSuccess;
  final String?
      fieldError; // null if general error, field name if specific field error
  final String message;

  // Semester-specific validation errors (for backward compatibility)
  final String? templateError;
  final String? yearError;
  final String? nameError;

  const ValidationResult({
    required this.isSuccess,
    this.fieldError,
    this.message = '',
    this.templateError,
    this.yearError,
    this.nameError,
  });

  // Backward compatibility getter
  bool get isValid => isSuccess;

  // Named constructor for semester validation (original pattern)
  const ValidationResult.semester({
    required bool isValid,
    this.templateError,
    this.yearError,
    this.nameError,
  })  : isSuccess = isValid,
        fieldError = null,
        message = '';

  // Factory constructors for common cases (new generic pattern)
  factory ValidationResult.success(
      [String message = 'Operation completed successfully']) {
    return ValidationResult(
      isSuccess: true,
      message: message,
    );
  }

  factory ValidationResult.fieldError(String field, String message) {
    return ValidationResult(
      isSuccess: false,
      fieldError: field,
      message: message,
    );
  }

  factory ValidationResult.generalError(String message) {
    return ValidationResult(
      isSuccess: false,
      message: message,
    );
  }
}
