import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_constants.dart';
import '../../../models/bill_payment_args.dart';

const _kBg = Color(0xFFFAF3F0);
const _kCardBorder = Color(0xFFEDE5DF);

class PaymentSuccessScreen extends StatelessWidget {
  final BillPaymentArgs args;
  const PaymentSuccessScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final submittedAt = DateFormat('d MMM yyyy, HH:mm').format(DateTime.now());

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar (no back button — terminal state)
            Container(
              color: AppColors.primary,
              height: AppSizes.appBarHeight,
              alignment: Alignment.center,
              child: Text(
                'Payment Submitted',
                style: GoogleFonts.poppins(
                  fontSize: AppSizes.fontL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cardWhite,
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),

                      // Green check circle
                      Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF4CAF50),
                          size: 56,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Payment Submitted!',
                        style: GoogleFonts.poppins(
                          fontSize: AppSizes.fontXL,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your slip has been sent to the host.\nThey will confirm your payment shortly.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: AppSizes.fontXS,
                          color: AppColors.textGray,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Status card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                          border: Border.all(color: _kCardBorder, width: 0.5),
                        ),
                        child: Column(
                          children: [
                            _StatusRow(
                                label: 'Event', value: args.eventName),
                            const Divider(
                                height: 0,
                                thickness: 0.5,
                                color: _kCardBorder),
                            _StatusRow(
                              label: 'Amount',
                              value: '฿${args.amount.toInt()}',
                              valueColor: AppColors.primary,
                              valueBold: true,
                            ),
                            const Divider(
                                height: 0,
                                thickness: 0.5,
                                color: _kCardBorder),
                            _StatusRow(
                                label: 'Submitted', value: submittedAt),
                            const Divider(
                                height: 0,
                                thickness: 0.5,
                                color: _kCardBorder),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Text(
                                    'Status',
                                    style: GoogleFonts.poppins(
                                      fontSize: AppSizes.fontXS,
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF8E1),
                                      borderRadius:
                                          BorderRadius.circular(AppSizes.radiusPill),
                                      border: Border.all(
                                          color: const Color(0xFFFFC107),
                                          width: 0.5),
                                    ),
                                    child: Text(
                                      'Pending review',
                                      style: GoogleFonts.poppins(
                                        fontSize: AppSizes.fontXXS,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFE65100),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Back to event button
                      SizedBox(
                        width: double.infinity,
                        height: AppSizes.buttonHeight,
                        child: OutlinedButton(
                          onPressed: () {
                            // Pop back to event detail (3 screens back)
                            while (context.canPop()) {
                              context.pop();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusPill),
                            ),
                          ),
                          child: Text(
                            'Back to event',
                            style: GoogleFonts.poppins(
                              fontSize: AppSizes.fontML,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: bottomPad + 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool valueBold;
  const _StatusRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textDark,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontXS,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                fontSize: AppSizes.fontXS,
                fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
