class Formatters {
  static String currency(num value) => 'Rs. ${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';
}
