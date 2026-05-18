class BillPaymentArgs {
  final String eventName;
  final double amount;
  final int memberCount;
  final int memberIndex;

  const BillPaymentArgs({
    required this.eventName,
    required this.amount,
    required this.memberCount,
    required this.memberIndex,
  });
}
