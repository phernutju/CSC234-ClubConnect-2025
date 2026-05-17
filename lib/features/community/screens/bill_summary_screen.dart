import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/smart_bill_model.dart';
import '../../../models/smart_pay_bill_args.dart';
import '../../../providers/smart_bill_provider.dart';
import '../../../providers/auth_provider.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFFFF6B4A);
const _kBg      = Color(0xFFFDF5F0);
const _kCream   = Color(0xFFFAECE7);
const _kBorder  = Color(0xFFF0C4B0);
const _kDark    = Color(0xFF4A1B0C);
const _kMuted   = Color(0xFF9A7A6A);
const _kSuccess = Color(0xFF2E9E5B);

const _kAvatarColors = [
  Color(0xFFFFB347), Color(0xFF77DD77), Color(0xFF89CFF0),
  Color(0xFFCDA4DE), Color(0xFFFF9F80), Color(0xFFAEC6CF),
  Color(0xFFFFD1DC), Color(0xFFB5EAD7),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class BillSummaryScreen extends StatefulWidget {
  final String communityId;
  final String eventId;
  final String billId;
  final bool isCurrentUserHost;

  const BillSummaryScreen({
    super.key,
    required this.communityId,
    required this.eventId,
    required this.billId,
    this.isCurrentUserHost = false,
  });

  @override
  State<BillSummaryScreen> createState() => _BillSummaryScreenState();
}

class _BillSummaryScreenState extends State<BillSummaryScreen> {
  String? _expandedMemberId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<SmartBillProvider>();
      p.loadBill(widget.communityId, widget.eventId, widget.billId);
      if (widget.isCurrentUserHost) {
        p.loadAllPayments(widget.communityId, widget.eventId, widget.billId);
      } else {
        final uid = context.read<AppAuthProvider>().user?.uid;
        if (uid != null && uid.isNotEmpty) {
          p.loadMyPayment(
              widget.communityId, widget.eventId, widget.billId, uid);
        }
      }
    });
  }

  Future<void> _goToPay(BuildContext ctx) async {
    final provider = ctx.read<SmartBillProvider>();
    final bill = provider.bill;
    if (bill == null) return;

    final uid = ctx.read<AppAuthProvider>().user?.uid ?? '';
    final myShare = provider.getMemberShare(uid);
    final myItems = provider.items
        .where((item) => item.payerIds.contains(uid))
        .map((item) =>
            SmartPayBillItem(name: item.name, myShare: item.pricePerPayer))
        .toList();

    final me = bill.members.firstWhere((m) => m.uid == uid,
        orElse: () => SmartBillMember(uid: uid, name: 'Me'));
    final host = bill.members.firstWhere((m) => m.uid == bill.hostId,
        orElse: () => SmartBillMember(uid: bill.hostId, name: 'Host'));

    await ctx.push<bool>(
      '/bill-payment',
      extra: SmartPayBillArgs(
        communityId: widget.communityId,
        eventId: widget.eventId,
        billId: bill.id,
        billName: bill.name,
        memberName: me.name,
        myShare: myShare,
        myItems: myItems,
        qrImageUrl: bill.hostPromptPayQrUrl,
        hostName: host.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SmartBillProvider>();
    final bill = provider.bill;
    final items = provider.items;
    final paymentStatus = provider.myPayment?.status;
    final hasPaid = paymentStatus == 'verifying' || paymentStatus == 'verified';
    final bottomPad = MediaQuery.of(context).padding.bottom;

    if (provider.isLoading && bill == null) {
      return _loadingScaffold();
    }

    if (bill == null) {
      return _emptyScaffold();
    }

    final memberTotals = provider.getMemberTotals();

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(bill),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.isCurrentUserHost &&
                          bill.status == SmartBillStatus.settled) ...[
                        _SettledBanner(),
                        const SizedBox(height: 12),
                      ],
                      if (!widget.isCurrentUserHost && hasPaid) ...[
                        _PaidBanner(),
                        const SizedBox(height: 12),
                      ],
                      _buildItemsCard(items),
                      const SizedBox(height: 20),
                      if (widget.isCurrentUserHost)
                        _buildPaymentStatusSection(bill, provider)
                      else
                        _buildMemberTotals(bill, memberTotals),
                      const SizedBox(height: 20),
                      _buildQrSection(bill),
                      SizedBox(height: bottomPad + 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: widget.isCurrentUserHost
                ? _buildHostFooter(bottomPad, provider)
                : _buildFooter(bottomPad, hasPaid: hasPaid),
          ),
        ],
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar(SmartBillModel bill) {
    return Container(
      color: _kPrimary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: 64,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Colors.white, size: 22),
              onPressed: () => context.pop(),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill.name,
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis),
                  Text(
                    '${bill.members.length} members · Total ฿${bill.totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Items card ────────────────────────────────────────────────────────────
  Widget _buildItemsCard(List<SmartBillItemModel> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('BILL ITEMS'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder)),
          child: items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                      child: Text('No items',
                          style: TextStyle(color: _kMuted))))
              : Column(
                  children: items.asMap().entries.map((e) {
                    final isLast = e.key == items.length - 1;
                    final item = e.value;
                    return Column(
                      children: [
                        _ItemRow(
                          item: item,
                          members: context
                              .read<SmartBillProvider>()
                              .bill
                              ?.members ??
                              [],
                        ),
                        if (!isLast)
                          const Divider(height: 1, color: _kBorder),
                      ],
                    );
                  }).toList(),
                ),
        ),
        // Total strip
        Container(
          decoration: const BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Text('Total',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 14)),
            const Spacer(),
            Text(
              '฿${items.fold(0.0, (s, i) => s + i.price).toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ]),
        ),
      ],
    );
  }

  // ── Member totals ─────────────────────────────────────────────────────────
  Widget _buildMemberTotals(
      SmartBillModel bill, Map<String, double> totals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('EACH MEMBER\'S SHARE'),
        const SizedBox(height: 8),
        ...bill.members.asMap().entries.map((e) {
          final idx = e.key;
          final member = e.value;
          final amount = totals[member.uid] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder)),
              child: Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      _kAvatarColors[idx % _kAvatarColors.length],
                  child: Text(
                    member.initials,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name,
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kDark)),
                      if (member.uid == bill.hostId)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                              color: _kCream,
                              borderRadius:
                                  BorderRadius.circular(4)),
                          child: Text('Host',
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: _kPrimary,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
                Text(
                  '฿${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary),
                ),
              ]),
            ),
          );
        }),
      ],
    );
  }

  // ── QR section ────────────────────────────────────────────────────────────
  Widget _buildQrSection(SmartBillModel bill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('PROMPTPAY QR'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder)),
          padding: const EdgeInsets.all(20),
          child: bill.hostPromptPayQrUrl.isEmpty
              ? Column(
                  children: [
                    const Icon(Icons.qr_code_2,
                        size: 48, color: _kBorder),
                    const SizedBox(height: 8),
                    Text('No QR code yet',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: _kMuted)),
                  ],
                )
              : Column(
                  children: [
                    Text('Scan to pay',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kDark)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        bill.hostPromptPayQrUrl,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image,
                                size: 80, color: _kBorder),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter(double bottomPad, {required bool hasPaid}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_kBg.withValues(alpha: 0), _kBg],
            ),
          ),
        ),
        Container(
          color: _kBg,
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, bottomPad > 0 ? bottomPad : 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: hasPaid ? null : () => _goToPay(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasPaid ? _kSuccess : _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: Text(
                hasPaid
                    ? 'Slip sent — awaiting confirmation'
                    : 'Pay my share',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Loading / empty scaffolds ─────────────────────────────────────────────
  Widget _loadingScaffold() {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        _AppBarPlaceholder(),
        const Expanded(
            child: Center(
                child: CircularProgressIndicator(color: _kPrimary))),
      ]),
    );
  }

  Widget _emptyScaffold() {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        _AppBarPlaceholder(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 64, color: _kBorder),
                const SizedBox(height: 12),
                Text('Bill not found',
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: _kMuted)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ── Payment status section (host view) ────────────────────────────────────
  Widget _buildPaymentStatusSection(
      SmartBillModel bill, SmartBillProvider provider) {
    final payments = provider.allPayments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('PAYMENT STATUS'),
        const SizedBox(height: 8),
        ...bill.members.asMap().entries.map((e) {
          final idx = e.key;
          final member = e.value;
          final payment =
              payments.where((p) => p.userId == member.uid).firstOrNull;
          final status = payment?.status ?? 'pending';
          final isVerified = status == 'verified';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onLongPress: () => setState(() {
                _expandedMemberId =
                    _expandedMemberId == member.uid ? null : member.uid;
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: isVerified ? const Color(0xFFE8F9F0) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isVerified ? const Color(0xFF86EFAC) : _kBorder,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              _kAvatarColors[idx % _kAvatarColors.length],
                          child: Text(member.initials,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member.name,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _kDark)),
                              if (member.uid == bill.hostId)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                      color: _kCream,
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text('Host',
                                      style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          color: _kPrimary,
                                          fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                        ),
                        _PaymentStatusChip(status: status),
                      ]),
                    ),
                    if (payment?.receiptUrl != null &&
                        (status == 'verifying' || status == 'review'))
                      _buildVerifyActions(member.uid, payment!),
                    if (payment?.receiptUrl != null && status == 'verified')
                      _buildSlipPreview(payment!),
                    if (_expandedMemberId == member.uid)
                      _buildInlineActions(member.uid, member.name, status, provider),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInlineActions(
      String userId, String memberName, String status, SmartBillProvider provider) {
    final isVerified = status == 'verified';
    final subtitle = isVerified
        ? '$memberName is marked as paid. Tap Unverify to cancel.'
        : 'Has $memberName paid? Tap Verify to confirm.';
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8F5),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: _kBorder),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 12, color: _kMuted),
          ),
          const SizedBox(height: 10),
          if (isVerified)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  setState(() => _expandedMemberId = null);
                  await provider.unverifyMemberPayment(
                      widget.communityId,
                      widget.eventId,
                      widget.billId,
                      userId);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Unverify',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  setState(() => _expandedMemberId = null);
                  await provider.verifyMemberPayment(
                      widget.communityId,
                      widget.eventId,
                      widget.billId,
                      userId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kSuccess,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text('Verify',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlipPreview(SmartPaymentModel payment) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF0FDF4),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0xFF86EFAC)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              payment.receiptUrl!,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                color: _kCream,
                child: const Center(
                    child: Icon(Icons.broken_image, color: _kBorder)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyActions(String userId, SmartPaymentModel payment) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8F5),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: _kBorder),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              payment.receiptUrl!,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                color: _kCream,
                child: const Center(
                    child: Icon(Icons.broken_image, color: _kBorder)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context
                    .read<SmartBillProvider>()
                    .rejectMemberPayment(widget.communityId, widget.eventId,
                        widget.billId, userId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Reject',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context
                    .read<SmartBillProvider>()
                    .verifyMemberPayment(widget.communityId, widget.eventId,
                        widget.billId, userId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kSuccess,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text('Verify',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Host footer ───────────────────────────────────────────────────────────
  Widget _buildHostFooter(double bottomPad, SmartBillProvider provider) {
    final settled = provider.bill?.status == SmartBillStatus.settled;
    final canSettle = provider.canSettle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_kBg.withValues(alpha: 0), _kBg],
            ),
          ),
        ),
        Container(
          color: _kBg,
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, bottomPad > 0 ? bottomPad : 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: settled || !canSettle
                  ? null
                  : () async {
                      final ok = await provider.settleBill(widget.communityId,
                          widget.eventId, widget.billId);
                      if (!ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Could not settle bill.')));
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    settled ? _kSuccess : canSettle ? _kPrimary : null,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: Text(
                settled
                    ? 'Bill Settled'
                    : canSettle
                        ? 'Settle Bill'
                        : 'Waiting for all payments',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Item row widget ───────────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final SmartBillItemModel item;
  final List<SmartBillMember> members;

  const _ItemRow({required this.item, required this.members});

  @override
  Widget build(BuildContext context) {
    final payerNames = item.payerIds
        .map((uid) {
          final m = members.where((m) => m.uid == uid).firstOrNull;
          return m?.name ?? uid;
        })
        .join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kDark)),
                if (payerNames.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(payerNames,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: _kMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: _kCream,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '฿${item.pricePerPayer.toStringAsFixed(2)}/person',
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: _kPrimary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '฿${item.price.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kDark),
          ),
        ],
      ),
    );
  }
}

// ── Paid banner ───────────────────────────────────────────────────────────────
class _PaidBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F9F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF86EFAC), width: 0.5),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFF15803D), size: 18),
          const SizedBox(width: 8),
          Text('Slip sent — waiting for host confirmation',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF15803D))),
        ]),
      );
}

// ── Shared small widgets ──────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _kMuted,
          letterSpacing: 0.9));
}

class _AppBarPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kPrimary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: 56,
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                color: Colors.white),
            onPressed: () => context.pop(),
          ),
          Text('Bill Summary',
              style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ]),
      ),
    );
  }
}

// ── Settled banner ────────────────────────────────────────────────────────────
class _SettledBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F9F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF86EFAC), width: 0.5),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle,
              color: Color(0xFF15803D), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Bill settled — all payments confirmed',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF15803D))),
          ),
        ]),
      );
}

// ── Payment status chip ───────────────────────────────────────────────────────
class _PaymentStatusChip extends StatelessWidget {
  final String status;
  const _PaymentStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;
    switch (status) {
      case 'verified':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'Verified';
        break;
      case 'review':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'Review Pending';
        break;
      case 'verifying':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        label = 'Verifying';
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = 'Rejected';
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg)),
    );
  }
}
