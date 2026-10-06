class Validators {
  static String? required(String? value, [String message = 'This field is required']) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required.';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a valid phone number.';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    final sriLankanRegex = RegExp(r'^(?:(?:\+94|0094|94|0)?[1-9]\d{8})$');
    if (!sriLankanRegex.hasMatch(cleaned)) {
      return 'Enter a valid phone number (e.g. 077 123 4567).';
    }
    return null;
  }

  static String normalizePhone(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    final match = RegExp(r'^(?:(?:\+94|0094|94|0)?)([1-9]\d{8})$').firstMatch(cleaned);
    if (match != null) {
      final national = match.group(1)!;
      final prefix = national.substring(0, 2);
      final p1 = national.substring(2, 5);
      final p2 = national.substring(5);
      return '+94 $prefix $p1 $p2';
    }
    return value.trim();
  }

  static String? nic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'National ID (NIC) is required.';
    }
    final cleaned = value.trim().toUpperCase();
    final oldNicRegex = RegExp(r'^[0-9]{9}[VX]$');
    final newNicRegex = RegExp(r'^[0-9]{12}$');
    if (!oldNicRegex.hasMatch(cleaned) && !newNicRegex.hasMatch(cleaned)) {
      return 'Enter a valid NIC (e.g. 123456789V or 12 digits).';
    }
    return null;
  }

  static String? vehiclePlate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vehicle number is required.';
    }
    final cleaned = value.trim().toUpperCase();
    final plateRegex = RegExp(r'^(?:(?:[A-Z]{2}[-\s]?)?[A-Z]{1,3}[-\s]?\d{4}|(?:[A-Z]{2}[-\s]?)?\d{2,3}[-\s]?\d{4})$');
    if (!plateRegex.hasMatch(cleaned)) {
      return 'Enter a valid vehicle number (e.g. WP BDF-4821).';
    }
    return null;
  }

  static String? postalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Postal code is optional
    }
    final cleaned = value.trim();
    if (!RegExp(r'^\d{5}$').hasMatch(cleaned)) {
      return 'Enter a valid 5-digit postal code.';
    }
    return null;
  }

  static String? addressLine1(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address Line 1 is required.';
    }
    if (value.trim().length < 3) {
      return 'Please enter a valid street address.';
    }
    return null;
  }

  static String? city(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City or Town is required.';
    }
    if (value.trim().length < 2) {
      return 'Please enter a valid city or town.';
    }
    return null;
  }
}
