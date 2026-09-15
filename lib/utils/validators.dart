/// Shared input validation helpers
class Validators {
  /// Check if a string is null or empty after trimming
  static bool isNullOrEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Validate password meets minimum length requirement
  static String? validatePassword(String? password, {int minLength = 6}) {
    if (isNullOrEmpty(password)) {
      return 'Password is required';
    }
    if (password!.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Validate two passwords match
  static String? validatePasswordMatch(String? password, String? confirm) {
    if (password != confirm) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate username is not empty
  static String? validateUsername(String? username) {
    if (isNullOrEmpty(username)) {
      return 'Username is required';
    }
    return null;
  }

  /// Validate email format (basic)
  static String? validateEmail(String? email) {
    if (isNullOrEmpty(email)) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email!.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Ensure a text field is not empty
  static String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (isNullOrEmpty(value)) {
      return '$fieldName is required';
    }
    return null;
  }
}
