// TODO: replace with Firestore data
import '../models/smart_bill_model.dart';
import '../models/smart_pay_bill_args.dart';

const mockBillId    = 'bill_mock_001';
const mockHostQrUrl = 'https://storage.example.com/qr/alice_promptpay.png';
const mockSlipUrl   = 'https://storage.example.com/slips/pay_001.jpg';

final mockBillMembers = [
  SmartBillMember(uid: 'user_001', name: 'Alice Nakamura'),
  SmartBillMember(uid: 'user_002', name: 'Bob Tanaka'),
  SmartBillMember(uid: 'user_003', name: 'Chloe Wongsa'),
  SmartBillMember(uid: 'user_004', name: 'David Lim'),
];

final mockBillItems = [
  SmartBillItemModel(
    id: 'item_001',
    name: 'Pizza Margherita (large)',
    price: 320.0,
    payerIds: ['user_001', 'user_002', 'user_003', 'user_004'],
  ),
  SmartBillItemModel(
    id: 'item_002',
    name: 'Craft Beer (x2)',
    price: 180.0,
    payerIds: ['user_001', 'user_002'],
  ),
  SmartBillItemModel(
    id: 'item_003',
    name: 'Caesar Salad',
    price: 120.0,
    payerIds: ['user_003'],
  ),
  SmartBillItemModel(
    id: 'item_004',
    name: 'Service Charge (10%)',
    price: 50.0,
    payerIds: ['user_001', 'user_002', 'user_003', 'user_004'],
  ),
];

final mockBill = SmartBillModel(
  id: mockBillId,
  name: 'Friday Night Dinner',
  hostId: 'user_001',
  hostPromptPayQrUrl: mockHostQrUrl,
  members: mockBillMembers,
  totalAmount: 670.0,
  status: SmartBillStatus.published,
  createdAt: DateTime(2026, 5, 11),
);

// Bob Tanaka's pay-bill args (current user = user_002)
final mockBobPayArgs = SmartPayBillArgs(
  communityId: 'community_mock_001',
  eventId: 'event_mock_001',
  billId: mockBillId,
  billName: 'Friday Night Dinner',
  memberName: 'Bob Tanaka',
  myShare: 182.5,
  myItems: [
    SmartPayBillItem(name: 'Pizza Margherita (large)', myShare: 80.0),
    SmartPayBillItem(name: 'Craft Beer (x2)',          myShare: 90.0),
    SmartPayBillItem(name: 'Service Charge (10%)',     myShare: 12.5),
  ],
  qrImageUrl: mockHostQrUrl,
  hostName: 'Alice Nakamura',
);

// AI verification mock result for Step 1
final mockVerificationResult = AiVerificationResult(
  detectedAmount: 182.50,
  expectedAmount: 182.50,
  recipientMatch: true,
  result: 'match',
);
