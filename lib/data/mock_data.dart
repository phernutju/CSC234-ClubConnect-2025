import '../models/bill_model.dart';

// Items sum: user001=450, user002=340, user003=210.67 → total=1000.67
final mockBill = BillModel(
  id: 'bill001',
  title: 'Car Kee',
  description: 'Dinner split from Car Kee restaurant',
  createdBy: 'user001',
  qrImageUrl:
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/QR_code_for_mobile_English_Wikipedia.svg/1200px-QR_code_for_mobile_English_Wikipedia.svg.png',
  totalAmount: 1000.67,
  status: BillStatus.partial,
  createdAt: DateTime(2026, 5, 10, 20, 0),
  participants: [
    BillParticipantModel(
      userId: 'user001',
      isPaid: true,
      paidAt: DateTime(2026, 5, 10, 22, 10),
      items: [
        BillItem(name: 'Lotus Duck', amount: 350.00),
        BillItem(name: 'Fried Rice', amount: 100.00),
      ],
    ),
    BillParticipantModel(
      userId: 'user002',
      isPaid: false,
      items: [
        BillItem(name: 'Tom Yum', amount: 280.00),
        BillItem(name: 'Coke', amount: 60.00),
      ],
    ),
    BillParticipantModel(
      userId: 'user003',
      isPaid: false,
      items: [
        BillItem(name: 'Pad Thai', amount: 150.00),
        BillItem(name: 'Mango Sticky Rice', amount: 60.67),
      ],
    ),
  ],
);
