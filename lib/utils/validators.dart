class Validators {
  // Validates that a field is not empty.
  // [fieldName] is the name of the form field to show in the error message.
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName cannot be empty.';
    }
    return null;
  }

  // Validates an email address using a regular expression.
  static String? validateEmail(String? value) {
    final emptyCheck = validateNotEmpty(value, 'Email');
    if (emptyCheck != null) {
      return emptyCheck;
    }

    // A common regex for email validation.
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    
    if (!emailRegex.hasMatch(value!)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  // Validates a password, checking for minimum length.
  static String? validatePassword(String? value) {
    final emptyCheck = validateNotEmpty(value, 'Password');
    if (emptyCheck != null) {
      return emptyCheck;
    }

    if (value!.length < 8) {
      return 'Password must be at least 8 characters long.';
    }
    return null;
  }

  // Validates a number field, like year or mileage.
  static String? validateNumber(String? value, String fieldName) {
    final emptyCheck = validateNotEmpty(value, fieldName);
    if (emptyCheck != null) {
      return emptyCheck;
    }

    if (int.tryParse(value!) == null) {
      return '$fieldName must be a valid number.';
    }
    return null;
  }
  
  // Validates a phone number (simple check for now).
  static String? validatePhoneNumber(String? value) {
    final emptyCheck = validateNotEmpty(value, 'Phone number');
    if (emptyCheck != null) {
      return emptyCheck;
    }

    if (value!.length < 10) {
      return 'Please enter a valid phone number.';
    }
    return null;
  }
}
