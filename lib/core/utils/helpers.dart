class Helpers {
  static bool isValidEmail(String value) =>
      RegExp(r'^[^@]+@[^@]+\\.[^@]+$').hasMatch(value);
}
