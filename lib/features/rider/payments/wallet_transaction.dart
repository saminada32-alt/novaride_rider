class WalletTransaction {
  final int id;
  final String type;
  final double amount;
  final String? pickupAddress;
  final String? dropoffAddress;
  final String? paymentMethod;
  final DateTime? createdAt;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.pickupAddress,
    this.dropoffAddress,
    this.paymentMethod,
    this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> j) {
    final created = j['createdAt'];
    return WalletTransaction(
      id: j['id'] is int ? j['id'] as int : int.parse(j['id'].toString()),
      type: j['type']?.toString() ?? 'RIDE_PAYMENT',
      amount: double.tryParse(j['amount']?.toString() ?? '0') ?? 0,
      pickupAddress: j['pickupAddress']?.toString(),
      dropoffAddress: j['dropoffAddress']?.toString(),
      paymentMethod: j['paymentMethod']?.toString(),
      createdAt: created != null ? DateTime.tryParse(created.toString()) : null,
    );
  }
}
