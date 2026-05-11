import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/app_constants.dart';
import '../../../models/bill_payment_args.dart';

const _kBg = Color(0xFFFAF3F0);
const _kCardBorder = Color(0xFFEDE5DF);

// ── Screen ────────────────────────────────────────────────────────────────────

class BillPaymentScreen extends StatefulWidget {
  final BillPaymentArgs args;
  const BillPaymentScreen({super.key, required this.args});

  @override
  State<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends State<BillPaymentScreen> {
  XFile? _slip;
  bool _confirming = false;

  Future<void> _pickSlip() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _slip = picked);
  }

  void _removeSlip() => setState(() => _slip = null);

  Future<void> _confirm() async {
    if (_slip == null || _confirming) return;
    setState(() => _confirming = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _confirming = false);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PaymentSubmittedDialog(amount: widget.args.amount),
    );
    if (mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final args = widget.args;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          Column(
            children: [
              _BillAppBar(title: 'Payment'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShareCard(args: args),
                      const SizedBox(height: 14),
                      _QrSection(amount: args.amount),
                      const SizedBox(height: 14),
                      _SlipSection(
                        slip: _slip,
                        onPick: _pickSlip,
                        onRemove: _removeSlip,
                      ),
                      SizedBox(height: 100 + bottomPad),
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
            child: _ConfirmFooter(
              amount: args.amount,
              enabled: _slip != null && !_confirming,
              loading: _confirming,
              bottomPad: bottomPad,
              onTap: _confirm,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Your share card ───────────────────────────────────────────────────────────

class _ShareCard extends StatelessWidget {
  final BillPaymentArgs args;
  const _ShareCard({required this.args});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: _kCardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your share',
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontXS,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '฿${args.amount.toInt()}',
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            args.eventName,
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${args.memberIndex} of ${args.memberCount} members',
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontXXS,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

// ── QR section ────────────────────────────────────────────────────────────────

class _QrSection extends StatelessWidget {
  final double amount;
  const _QrSection({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: _kCardBorder, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            'Scan to pay',
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use your banking app to scan',
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontXXS,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kCardBorder, width: 0.5),
            ),
            child: CustomPaint(
              size: const Size(180, 180),
              painter: _QrPainter('$amount'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '',
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Host — PromptPay / Bank transfer',
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontXXS,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

// ── QR painter ────────────────────────────────────────────────────────────────

class _QrPainter extends CustomPainter {
  final String seed;
  const _QrPainter(this.seed);

  static const int _cells = 21;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _cells;
    final black = Paint()..color = Colors.black;
    final white = Paint()..color = Colors.white;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), white);

    void fillRect(int col, int row, [int w = 1, int h = 1]) {
      canvas.drawRect(
          Rect.fromLTWH(col * cell, row * cell, w * cell, h * cell), black);
    }

    void clearRect(int col, int row, [int w = 1, int h = 1]) {
      canvas.drawRect(
          Rect.fromLTWH(col * cell, row * cell, w * cell, h * cell), white);
    }

    void drawFinder(int ox, int oy) {
      fillRect(ox, oy, 7, 7);
      clearRect(ox + 1, oy + 1, 5, 5);
      fillRect(ox + 2, oy + 2, 3, 3);
    }

    // Finder patterns
    drawFinder(0, 0);
    drawFinder(_cells - 7, 0);
    drawFinder(0, _cells - 7);

    // Timing strips
    for (int i = 8; i <= _cells - 9; i++) {
      if (i.isEven) {
        fillRect(i, 6);
        fillRect(6, i);
      }
    }

    // Data modules
    final rng = seed.codeUnits.fold(0, (h, c) => (h * 31 + c) & 0x7fffffff);
    final reserved = _buildReserved();

    for (int r = 0; r < _cells; r++) {
      for (int c = 0; c < _cells; c++) {
        if (reserved[r * _cells + c]) continue;
        final idx = r * _cells + c;
        final hash = (rng ^ (idx * 2654435761)) & 0x7fffffff;
        if ((hash >> (idx % 23)) & 1 == 1) fillRect(c, r);
      }
    }
  }

  List<bool> _buildReserved() {
    final r = List<bool>.filled(_cells * _cells, false);
    void mark(int col, int row, [int w = 1, int h = 1]) {
      for (int dr = 0; dr < h; dr++) {
        for (int dc = 0; dc < w; dc++) {
          if (row + dr < _cells && col + dc < _cells) {
            r[(row + dr) * _cells + (col + dc)] = true;
          }
        }
      }
    }

    mark(0, 0, 8, 8);
    mark(_cells - 8, 0, 8, 8);
    mark(0, _cells - 8, 8, 8);
    for (int i = 6; i < _cells - 8; i++) {
      mark(i, 6);
      mark(6, i);
    }
    return r;
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.seed != seed;
}

// ── Slip upload section ───────────────────────────────────────────────────────

class _SlipSection extends StatelessWidget {
  final XFile? slip;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  const _SlipSection({
    required this.slip,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload payment slip',
          style: GoogleFonts.poppins(
            fontSize: AppSizes.fontSM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        if (slip == null)
          _UploadArea(onTap: onPick)
        else
          _SlipPreview(slip: slip!, onRemove: onRemove),
      ],
    );
  }
}

class _UploadArea extends StatelessWidget {
  final VoidCallback onTap;
  const _UploadArea({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: CustomPaint(
          painter: _DashBorderPainter(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.upload_file_outlined,
                  color: AppColors.primary, size: 32),
              const SizedBox(height: 8),
              Text(
                'Tap to attach slip',
                style: GoogleFonts.poppins(
                  fontSize: AppSizes.fontSM,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'JPG or PNG',
                style: GoogleFonts.poppins(
                  fontSize: AppSizes.fontXXS,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFf07050).withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dash = 6.0;
    const gap = 4.0;
    const r = AppSizes.radiusM;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(r)));

    _drawDashedPath(canvas, path, paint, dash, gap);
  }

  void _drawDashedPath(
      Canvas canvas, Path path, Paint paint, double dash, double gap) {
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      double d = 0;
      while (d < m.length) {
        final end = math.min(d + dash, m.length);
        canvas.drawPath(m.extractPath(d, end), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _SlipPreview extends StatelessWidget {
  final XFile slip;
  final VoidCallback onRemove;
  const _SlipPreview({required this.slip, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: _kCardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 60,
              child: kIsWeb
                  ? Image.network(slip.path, fit: BoxFit.cover)
                  : Image.file(File(slip.path), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slip.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: AppSizes.fontXS,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ready to submit',
                  style: GoogleFonts.poppins(
                    fontSize: AppSizes.fontXXS,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: AppColors.textGray),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confirm footer ────────────────────────────────────────────────────────────

class _ConfirmFooter extends StatelessWidget {
  final double amount;
  final bool enabled;
  final bool loading;
  final double bottomPad;
  final VoidCallback onTap;
  const _ConfirmFooter({
    required this.amount,
    required this.enabled,
    required this.loading,
    required this.bottomPad,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 32,
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
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad > 0 ? bottomPad : 24),
          child: SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: ElevatedButton(
              onPressed: enabled ? onTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'Confirm payment',
                      style: GoogleFonts.poppins(
                        fontSize: AppSizes.fontML,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cardWhite,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Payment submitted dialog ──────────────────────────────────────────────────

class _PaymentSubmittedDialog extends StatelessWidget {
  final double amount;
  const _PaymentSubmittedDialog({required this.amount});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('\u{1F389}', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'Payment submitted!',
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontML,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '฿${amount.toInt()}',
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontXL,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Pending confirmation',
              style: GoogleFonts.poppins(
                fontSize: AppSizes.fontXXS,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD97706),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your slip has been sent to the host for confirmation.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontXXS,
              color: AppColors.textGray,
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
            ),
            child: Text(
              'Got it!',
              style: GoogleFonts.poppins(
                fontSize: AppSizes.fontML,
                fontWeight: FontWeight.w600,
                color: AppColors.cardWhite,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared app bar ────────────────────────────────────────────────────────────

class _BillAppBar extends StatelessWidget {
  final String title;
  const _BillAppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: AppSizes.appBarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.cardWhite),
              onPressed: () => context.pop(),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: AppSizes.fontL,
                fontWeight: FontWeight.w600,
                color: AppColors.cardWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
