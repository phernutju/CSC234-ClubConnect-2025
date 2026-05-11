/// A single item entry from the member's perspective when paying.
class SmartPayBillItem {
  final String name;
  final double myShare;
  const SmartPayBillItem({required this.name, required this.myShare});
}

/// Passed as go_router extra when navigating to /bill-payment.
class SmartPayBillArgs {
  final String billId;
  final String billName;
  final String memberName;
  final double myShare;
  final List<SmartPayBillItem> myItems;
  final String qrImageUrl;
  final String hostName;

  const SmartPayBillArgs({
    required this.billId,
    required this.billName,
    required this.memberName,
    required this.myShare,
    required this.myItems,
    this.qrImageUrl = '',
    required this.hostName,
  });
}
