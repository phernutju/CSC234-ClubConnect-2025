import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../models/smart_bill_model.dart';
import '../../../models/smart_pay_bill_args.dart';
import '../../../providers/smart_bill_provider.dart';
import '../../../providers/auth_provider.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFFD85A30);
const _kBg = Color(0xFFFDF5F0);
const _kCream = Color(0xFFFAECE7);
const _kBorder = Color(0xFFF0C4B0);
const _kDark = Color(0xFF4A1B0C);
const _kMuted = Color(0xFF9A7A6A);
const _kSuccess = Color(0xFF2E9E5B);

// ── Screen ────────────────────────────────────────────────────────────────────
class BillPaymentScreen extends StatefulWidget {
  final SmartPayBillArgs args;
  const BillPaymentScreen({super.key, required this.args});

  @override
  State<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends State<BillPaymentScreen> {
  int _step = 0; // 0 = pay, 1 = verifying, 2 = confirmed
  XFile? _slip;
  Uint8List? _slipBytes;
  bool _isVerifying = false;
  AiVerificationResult? _verificationResult;

  Future<void> _pickSlip() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _slip = picked;
        _slipBytes = bytes;
      });
    }
  }

  Future<void> _startVerification() async {
    if (_slipBytes == null) return;
    setState(() {
      _step = 1;
      _isVerifying = true;
    });
    try {
      final provider = context.read<SmartBillProvider>();
      final uid = context.read<AppAuthProvider>().user?.uid ?? '';
      final result = await provider.submitAndVerify(
        communityId: widget.args.communityId,
        eventId: widget.args.eventId,
        billId: widget.args.billId,
        userId: uid,
        amountDue: widget.args.myShare,
        slipBytes: _slipBytes!,
      );
      debugPrint('[SLIP] Verification completed with result: $result');
      if (mounted) {
        setState(() {
          _verificationResult = result;
          _isVerifying = false;
        });
        if (result != null && !result.isMatch) {
          _showAccessDenied();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showAccessDenied() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.block_rounded, color: Color(0xFFE24B4A), size: 24),
          const SizedBox(width: 8),
          Text('Access Denied',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE24B4A))),
        ]),
        content: Text(
          'Slip verification failed.\nThe amount or slip does not match the expected payment.',
          style: GoogleFonts.poppins(fontSize: 13, color: _kDark),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _step = 0;
                _slip = null;
                _slipBytes = null;
                _verificationResult = null;
              });
            },
            child: Text('Try Again',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: _kPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: _buildCurrentStep(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1:
        return _Step1(
          key: const ValueKey(1),
          slip: _slip,
          slipBytes: _slipBytes,
          isVerifying: _isVerifying,
          result: _verificationResult,
          args: widget.args,
          onDone: () => setState(() => _step = 2),
        );
      case 2:
        return _Step2(
          key: const ValueKey(2),
          args: widget.args,
          onBack: () => context.pop(true),
        );
      default:
        return _Step0(
          key: const ValueKey(0),
          args: widget.args,
          slip: _slip,
          slipBytes: _slipBytes,
          onPickSlip: _pickSlip,
          onVerify: _startVerification,
        );
    }
  }
}

// ── Step 0 — Pay ──────────────────────────────────────────────────────────────
class _Step0 extends StatelessWidget {
  final SmartPayBillArgs args;
  final XFile? slip;
  final Uint8List? slipBytes;
  final VoidCallback onPickSlip;
  final VoidCallback onVerify;

  const _Step0({
    super.key,
    required this.args,
    required this.slip,
    required this.slipBytes,
    required this.onPickSlip,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Column(
      children: [
        _AppBar(
          title: 'Pay bill',
          subtitle: '${args.billName} · ${args.memberName}',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad + 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bill items section
                _SectionLabel('BILL ITEMS'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Column(
                    children: args.myItems.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                  child: Text('No items',
                                      style: TextStyle(color: _kMuted))),
                            )
                          ]
                        : args.myItems.asMap().entries.map((e) {
                            final isLast = e.key == args.myItems.length - 1;
                            final item = e.value;
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  child: Row(children: [
                                    Expanded(
                                      child: Text(item.name,
                                          style: GoogleFonts.poppins(
                                              fontSize: 14, color: _kDark)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: _kCream,
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Text(
                                        '฿${item.myShare.toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _kPrimary),
                                      ),
                                    ),
                                  ]),
                                ),
                                if (!isLast)
                                  const Divider(height: 1, color: _kBorder),
                              ],
                            );
                          }).toList(),
                  ),
                ),
                // Your share strip
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
                    Text('My share',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 14)),
                    const Spacer(),
                    Text('฿${args.myShare.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ]),
                ),
                const SizedBox(height: 20),
                // Scan to pay section
                _SectionLabel('SCAN TO PAY'),
                const SizedBox(height: 8),
                _QrCard(qrImageUrl: args.qrImageUrl, hostName: args.hostName),
                const SizedBox(height: 20),
                // Upload slip section
                _SectionLabel('UPLOAD SLIP'),
                const SizedBox(height: 8),
                if (slip == null)
                  _DashedUploadBox(onTap: onPickSlip)
                else
                  _SlipPreviewTile(
                    slip: slip!,
                    slipBytes: slipBytes!,
                    onTap: onPickSlip,
                  ),
              ],
            ),
          ),
        ),
        _Footer(
          label: 'Verify with AI',
          enabled: slip != null,
          color: _kPrimary,
          onTap: onVerify,
          bottomPad: bottomPad,
        ),
      ],
    );
  }
}

// ── Step 1 — Verifying ────────────────────────────────────────────────────────
class _Step1 extends StatelessWidget {
  final XFile? slip;
  final Uint8List? slipBytes;
  final bool isVerifying;
  final AiVerificationResult? result;
  final SmartPayBillArgs args;
  final VoidCallback onDone;

  const _Step1({
    super.key,
    required this.slip,
    required this.slipBytes,
    required this.isVerifying,
    required this.result,
    required this.args,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Column(
      children: [
        _AppBar(
          title: 'Verifying slip',
          subtitle: 'AI is verifying your slip',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad + 100),
            child: Column(
              children: [
                // Slip preview card
                if (slip != null && slipBytes != null)
                  _SlipDocCard(slip: slip!, slipBytes: slipBytes!),
                const SizedBox(height: 16),
                // AI verification card
                _AiVerifyCard(
                  isVerifying: isVerifying,
                  result: result,
                  expectedAmount: args.myShare,
                  hostName: args.hostName,
                ),
              ],
            ),
          ),
        ),
        if (!isVerifying && result != null)
          _Footer(
            label: 'Done',
            enabled: true,
            color: _kSuccess,
            onTap: onDone,
            bottomPad: bottomPad,
          ),
      ],
    );
  }
}

// ── Step 2 — Confirmed ────────────────────────────────────────────────────────
class _Step2 extends StatelessWidget {
  final SmartPayBillArgs args;
  final VoidCallback onBack;

  const _Step2({
    super.key,
    required this.args,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final now = DateTime.now();
    final timeStr =
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    return Column(
      children: [
        // Green app bar
        Container(
          color: _kSuccess,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: const SizedBox(
            height: 56,
            child: Center(
              child: Text(
                'Payment sent!',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 24, 16, bottomPad + 100),
            child: Column(
              children: [
                // Green confirmed card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F9F0),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFF86EFAC), width: 0.5),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 14),
                      Text('Verified!',
                          style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _kSuccess)),
                      const SizedBox(height: 6),
                      Text(
                        'Your payment has been confirmed',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: const Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Payment summary card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(label: 'Bill name', value: args.billName),
                      const Divider(height: 1, color: _kBorder),
                      _SummaryRow(
                          label: 'Your share',
                          value: '฿${args.myShare.toStringAsFixed(2)}',
                          valueColor: _kPrimary,
                          bold: true),
                      const Divider(height: 1, color: _kBorder),
                      _SummaryRow(label: 'Transfer to', value: args.hostName),
                      const Divider(height: 1, color: _kBorder),
                      _SummaryRow(label: 'Date & time', value: timeStr),
                      const Divider(height: 1, color: _kBorder),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Text('Status',
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: _kMuted)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F9F0),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF86EFAC), width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle,
                                      size: 12, color: Color(0xFF15803D)),
                                  const SizedBox(width: 4),
                                  Text('Confirmed',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF15803D))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _Footer(
          label: 'Back to bill',
          enabled: true,
          color: _kSuccess,
          onTap: onBack,
          bottomPad: bottomPad,
        ),
      ],
    );
  }
}

// ── QR card ───────────────────────────────────────────────────────────────────
class _QrCard extends StatelessWidget {
  final String qrImageUrl;
  final String hostName;

  const _QrCard({required this.qrImageUrl, required this.hostName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Text('Scan to pay',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600, color: _kDark)),
          const SizedBox(height: 4),
          Text('Use your banking app to scan the QR',
              style: GoogleFonts.poppins(fontSize: 11, color: _kMuted)),
          const SizedBox(height: 16),
          if (qrImageUrl.isEmpty)
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                  color: _kCream, borderRadius: BorderRadius.circular(12)),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2, size: 60, color: _kBorder),
                ],
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                qrImageUrl,
                width: 160,
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 80, color: _kBorder),
              ),
            ),
          const SizedBox(height: 12),
          Text(hostName,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _kDark)),
          Text('PromptPay / Bank transfer',
              style: GoogleFonts.poppins(fontSize: 11, color: _kMuted)),
        ],
      ),
    );
  }
}

// ── Dashed upload box ─────────────────────────────────────────────────────────
class _DashedUploadBox extends StatelessWidget {
  final VoidCallback onTap;
  const _DashedUploadBox({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          color: _kCream,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomPaint(
          painter: _DashBorderPainter(color: _kPrimary),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.upload_file_outlined,
                  color: _kPrimary, size: 32),
              const SizedBox(height: 8),
              Text('Attach transfer slip',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _kPrimary)),
              Text('JPG or PNG',
                  style: GoogleFonts.poppins(fontSize: 11, color: _kMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Slip preview tile (Step 0 — after selection) ──────────────────────────────
class _SlipPreviewTile extends StatelessWidget {
  final XFile slip;
  final Uint8List slipBytes;
  final VoidCallback onTap;

  const _SlipPreviewTile({
    required this.slip,
    required this.slipBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(slipBytes,
                width: 60, height: 60, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slip.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kDark)),
                const SizedBox(height: 2),
                Text('Tap to change',
                    style: GoogleFonts.poppins(fontSize: 11, color: _kSuccess)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: _kSuccess, size: 20),
        ]),
      ),
    );
  }
}

// ── Slip document card (Step 1) ───────────────────────────────────────────────
class _SlipDocCard extends StatelessWidget {
  final XFile slip;
  final Uint8List slipBytes;

  const _SlipDocCard({required this.slip, required this.slipBytes});

  String get _sizeLabel {
    final kb = slipBytes.length / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: _kCream, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.image_outlined, color: _kPrimary, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slip.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _kDark)),
              const SizedBox(height: 2),
              Text(_sizeLabel,
                  style: GoogleFonts.poppins(fontSize: 11, color: _kMuted)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF8E6),
              borderRadius: BorderRadius.circular(20)),
          child: Text('Pending',
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD97706))),
        ),
      ]),
    );
  }
}

// ── AI verification card ──────────────────────────────────────────────────────
class _AiVerifyCard extends StatelessWidget {
  final bool isVerifying;
  final AiVerificationResult? result;
  final double expectedAmount;
  final String hostName;

  const _AiVerifyCard({
    required this.isVerifying,
    required this.result,
    required this.expectedAmount,
    required this.hostName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: isVerifying
          ? Column(
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                      color: _kPrimary, strokeWidth: 3),
                ),
                const SizedBox(height: 14),
                Text('AI is analysing your slip…',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _kDark)),
                const SizedBox(height: 4),
                Text('Please wait a moment',
                    style: GoogleFonts.poppins(fontSize: 12, color: _kMuted)),
              ],
            )
          : result == null
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                          color: Color(0xFFE8F9F0), shape: BoxShape.circle),
                      child: const Icon(Icons.verified_user_rounded,
                          color: _kSuccess, size: 32),
                    ),
                    const SizedBox(height: 10),
                    Text('Slip verified!',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kSuccess)),
                    const SizedBox(height: 4),
                    Text('Verified successfully',
                        style:
                            GoogleFonts.poppins(fontSize: 12, color: _kMuted)),
                    if (result!.reason.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: result!.isMatch
                              ? const Color(0xFFE8F9F0)
                              : const Color(0xFFFFEEEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          result!.reason,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: result!.isMatch
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFE24B4A)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(color: _kBorder),
                    _DetailRow(
                        label: 'Amount detected',
                        value: '฿${result!.detectedAmount.toStringAsFixed(2)}'),
                    _DetailRow(
                        label: 'Expected amount',
                        value: '฿${result!.expectedAmount.toStringAsFixed(2)}'),
                    _DetailRow(
                        label: 'Recipient',
                        value: hostName,
                        isSuccess: result!.recipientMatch),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: result!.isMatch
                                ? const Color(0xFFE8F9F0)
                                : const Color(0xFFFFEEEE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: result!.isMatch
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFFF9A9A),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                result!.isMatch
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 14,
                                color: result!.isMatch
                                    ? _kSuccess
                                    : const Color(0xFFE24B4A),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                result!.isMatch ? 'Match' : 'Mismatch',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: result!.isMatch
                                        ? _kSuccess
                                        : const Color(0xFFE24B4A)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool? isSuccess;

  const _DetailRow({required this.label, required this.value, this.isSuccess});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: _kMuted)),
          const Spacer(),
          if (isSuccess != null)
            Icon(
              isSuccess! ? Icons.check_circle : Icons.cancel,
              size: 14,
              color: isSuccess! ? _kSuccess : const Color(0xFFE24B4A),
            ),
          if (isSuccess != null) const SizedBox(width: 4),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _kDark)),
        ]),
      );
}

// ── Summary row ───────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor = _kDark,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: _kMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.end,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: valueColor)),
          ),
        ]),
      );
}

// ── Shared small widgets ──────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AppBar({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kPrimary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: 64,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              onPressed: () => context.pop(),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85)),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _Footer extends StatelessWidget {
  final String label;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;
  final double bottomPad;

  const _Footer({
    required this.label,
    required this.enabled,
    required this.color,
    required this.onTap,
    required this.bottomPad,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 28,
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
          padding:
              EdgeInsets.fromLTRB(16, 0, 16, bottomPad > 0 ? bottomPad : 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: enabled ? onTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                disabledBackgroundColor: color.withValues(alpha: 0.35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Dashed border painter ─────────────────────────────────────────────────────
class _DashBorderPainter extends CustomPainter {
  final Color color;
  const _DashBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 4.0;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(12)));
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + dash, m.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashBorderPainter old) => old.color != color;
}
