class PaymentModel {
  const PaymentModel({required this.amount, this.status = 'pending'});
  final double amount;
  final String status;
}
