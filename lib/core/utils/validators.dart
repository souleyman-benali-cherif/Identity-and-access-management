/// All real-time field validators used across the app.
/// Each function returns null on success, or an error string on failure.
class Validators {
  Validators._();

  /// Validates first or last name — at least 2 letters, strictly letters only (no numbers, symbols, spaces).
  static String? name(String? value, {String fieldLabel = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel cannot be empty.';
    }
    if (value.trim().length < 2) {
      return '$fieldLabel must be at least 2 characters.';
    }
    if (!RegExp(r"^[a-zA-ZÀ-ÿ]+$").hasMatch(value.trim())) {
      return '$fieldLabel must contain letters only (no numbers, symbols, or spaces).';
    }
    return null;
  }

  /// Validates personal email format (must contain @ and a dotted domain).
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email cannot be empty.';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  /// Validates phone number — strictly digits only 0-9.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number cannot be empty.';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
      return 'Phone number must contain digits only 0-9 (no spaces or symbols).';
    }
    return null;
  }

  /// Validates that a required text field is not empty.
  static String? required(String? value, {String fieldLabel = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel cannot be empty.';
    }
    return null;
  }

  /// Validates date of birth — cannot be in the future, cannot be empty.
  static String? dateOfBirth(DateTime? value, {bool checkStudentAge = false}) {
    if (value == null) {
      return 'Date of birth cannot be empty.';
    }
    if (value.isAfter(DateTime.now())) {
      return 'Date of birth cannot be in the future.';
    }
    if (checkStudentAge) {
      final age = _ageInYears(value);
      if (age < 16) {
        return 'Student must be at least 16 years old.';
      }
    }
    return null;
  }

  /// Validates a number field is within a given range.
  static String? numberInRange(int? value, int min, int max,
      {String fieldLabel = 'Value'}) {
    if (value == null) {
      return '$fieldLabel is required.';
    }
    if (value < min || value > max) {
      return '$fieldLabel must be between $min and $max.';
    }
    return null;
  }

  /// Validates that the confirm password matches the new password.
  static String? confirmPassword(String? value, String newPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != newPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }

  /// Validates that a year is not in the future.
  static String? notFutureYear(int? value, {String fieldLabel = 'Year'}) {
    if (value == null) {
      return '$fieldLabel is required.';
    }
    if (value > DateTime.now().year) {
      return '$fieldLabel cannot be in the future.';
    }
    return null;
  }

  /// Validates contractor access expiry date — must be in the future.
  static String? futureDate(DateTime? value, {String fieldLabel = 'Date'}) {
    if (value == null) {
      return '$fieldLabel is required.';
    }
    if (!value.isAfter(DateTime.now())) {
      return '$fieldLabel must be in the future.';
    }
    return null;
  }

  /// Validates international student stay duration — 6 to 24 months.
  static String? stayDuration(DateTime? start, DateTime? end) {
    if (start == null) return 'Stay start date is required.';
    if (end == null) return 'Stay end date is required.';
    if (!end.isAfter(start)) return 'End date must be after start date.';
    final months = (end.year - start.year) * 12 + end.month - start.month;
    if (months < 6 || months > 24) {
      return 'Stay duration must be between 6 and 24 months.';
    }
    return null;
  }

  /// Validates a security question answer — at least 2 characters.
  static String? securityAnswer(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'Answer must be at least 2 characters.';
    }
    return null;
  }

  /// Validates that a date is not in the future (for dates that must be past/today).
  static String? notFutureDate(DateTime? value, {String fieldLabel = 'Date'}) {
    if (value == null) {
      return '$fieldLabel is required.';
    }
    if (value.isAfter(DateTime.now())) {
      return '$fieldLabel cannot be in the future.';
    }
    return null;
  }

  /// Validates that a date string is in YYYY-MM-DD format and parses successfully.
  static String? validDateFormat(String? value, {String fieldLabel = 'Date'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel is required.';
    }
    try {
      DateTime.parse(value.trim());
      return null;
    } catch (_) {
      return '$fieldLabel must be in YYYY-MM-DD format.';
    }
  }

  /// Validates that a professor ID starts with the FAC prefix.
  static String? professorIdPrefix(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Professor ID is required.';
    }
    if (!value.trim().toUpperCase().startsWith('FAC')) {
      return 'Professor ID must start with "FAC".';
    }
    return null;
  }

  /// Validates that end date is after start date (both as string YYYY-MM-DD).
  static String? endDateAfterStartDate(String? endDateStr, String? startDateStr,
      {String fieldLabel = 'End date'}) {
    if (startDateStr == null || startDateStr.trim().isEmpty) {
      return 'Start date is required first.';
    }
    if (endDateStr == null || endDateStr.trim().isEmpty) {
      return '$fieldLabel is required.';
    }
    try {
      final start = DateTime.parse(startDateStr.trim());
      final end = DateTime.parse(endDateStr.trim());
      if (!end.isAfter(start)) {
        return '$fieldLabel must be after the start date.';
      }
      return null;
    } catch (_) {
      return 'Invalid date format.';
    }
  }

  /// Validates international student stay duration — 6 to 24 months (both as string YYYY-MM-DD).
  static String? stayDurationFromStrings(String? startStr, String? endStr) {
    if (startStr == null || startStr.trim().isEmpty) {
      return 'Stay start date is required.';
    }
    if (endStr == null || endStr.trim().isEmpty) {
      return 'Stay end date is required.';
    }
    try {
      final start = DateTime.parse(startStr.trim());
      final end = DateTime.parse(endStr.trim());
      if (!end.isAfter(start)) {
        return 'End date must be after start date.';
      }
      final months = (end.year - start.year) * 12 + end.month - start.month;
      if (months < 6) {
        return 'Stay duration must be at least 6 months.';
      }
      if (months > 24) {
        return 'Stay duration cannot exceed 24 months.';
      }
      return null;
    } catch (_) {
      return 'Invalid date format (use YYYY-MM-DD).';
    }
  }

  /// Calculates age in whole years from the given birth date.
  static int _ageInYears(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}
