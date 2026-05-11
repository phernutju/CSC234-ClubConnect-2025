// Shared data models for the Create-Bill → Bill-Summary flow.
// Kept as plain Dart; no Flutter imports.

class BillMemberData {
  final String initials;
  final String name;
  final String role;
  final bool isHost;
  final String status; // 'unpaid', 'pending', 'paid'
  const BillMemberData({
    required this.initials,
    required this.name,
    required this.role,
    required this.isHost,
    this.status = 'unpaid',
  });
}

class BillItemData {
  final String name;
  final double amount;
  const BillItemData({required this.name, required this.amount});
}

class BillData {
  final String eventName;
  final String hostName;
  final List<BillItemData> items;
  final List<BillMemberData> members;
  const BillData({
    required this.eventName,
    required this.hostName,
    required this.items,
    required this.members,
  });
}
