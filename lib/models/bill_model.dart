enum BillStatus { draft, pending, partial, completed }

class BillItem {
  final String name;
  final double amount;
  const BillItem({required this.name, required this.amount});
}

class BillParticipantModel {
  final String userId;
  final bool isPaid;
  final DateTime? paidAt;
  final List<BillItem> items;

  const BillParticipantModel({
    required this.userId,
    required this.isPaid,
    this.paidAt,
    required this.items,
  });

  double get total => items.fold(0.0, (sum, item) => sum + item.amount);
}

class BillModel {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final String? qrImageUrl;
  final double totalAmount;
  final BillStatus status;
  final DateTime createdAt;
  final List<BillParticipantModel> participants;

  const BillModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    this.qrImageUrl,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.participants,
  });
}
