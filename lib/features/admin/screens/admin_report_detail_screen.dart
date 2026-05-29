import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/report_model.dart' as fs;
import '../../../providers/report_provider.dart';
import '../../../services/report_service.dart';
import '../../../services/user_service.dart';
import '../models/report_model.dart';

class AdminReportDetailScreen extends StatelessWidget {
  final AdminReportModel report;

  const AdminReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _DarkHeader(report: report),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SeverityRow(report: report),
                  const SizedBox(height: 20),
                  _ReportCard(report: report),
                  const SizedBox(height: 24),
                  _ActionButtons(report: report),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkHeader extends StatelessWidget {
  final AdminReportModel report;
  const _DarkHeader({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top +
            MediaQuery.of(context).size.height * 0.05,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                report.id,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF797979),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${report.category} in ',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: report.groupName,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFFF6B4A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityRow extends StatelessWidget {
  final AdminReportModel report;
  const _SeverityRow({required this.report});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: report.aiDetectedLabel == 'AI detected'
                ? const Color(0xFFFFE5A0)
                : const Color(0xFFFF6B4A),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            report.aiDetectedLabel,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: report.aiDetectedLabel == 'AI detected'
                  ? const Color(0xFF000000)
                  : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final AdminReportModel report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'REPORT NO.', value: report.id),
          const SizedBox(height: 12),
          _InfoRow(label: 'SOURCE', value: report.source),
          const SizedBox(height: 12),
          _InfoRow(label: 'USER', value: '@${report.username}'),
          const SizedBox(height: 12),
          Text(
            'REPORTED MESSAGE',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF797979),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFF6B4A)),
            ),
            child: Text(
              report.reportedText,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF000000),
              ),
            ),
          ),
          if (report.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoRow(label: 'AI REASON', value: report.description),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF797979))),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF000000))),
      ],
    );
  }
}

class _ActionButtons extends StatefulWidget {
  final AdminReportModel report;
  const _ActionButtons({required this.report});

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  bool _isBanning = false;
  bool _isDismissing = false;

  Future<void> _onBan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Ban @${widget.report.username}?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: Text(
          'This will restrict the user from sending messages. You can unban them from the Banned Users tab.',
          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF797979)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: const Color(0xFF797979))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6868),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Ban',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isBanning = true);
    try {
      await UserService.banUser(
          widget.report.targetUserId, 'Violation of community guidelines', 'Permanently');
      final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await ReportService().updateReportStatus(
          widget.report.id, fs.ReportStatus.banned, adminUid);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User has been banned.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ban: $e')),
        );
      }
    }
  }

  Future<void> _onDismiss() async {
    setState(() => _isDismissing = true);
    try {
      final reportProvider = context.read<ReportProvider>();
      await reportProvider.updateReportStatus(
          widget.report.id, fs.ReportStatus.reviewed);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isDismissing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canBan = widget.report.targetUserId.isNotEmpty;

    return Column(
      children: [
        if (canBan)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isBanning ? null : _onBan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6868),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: _isBanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Ban @${widget.report.username}',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
            ),
          ),
        if (canBan) const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isDismissing ? null : _onDismiss,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFFDDDDDD)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: _isDismissing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.grey, strokeWidth: 2),
                  )
                : Text(
                    'Dismiss Report',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF000000)),
                  ),
          ),
        ),
      ],
    );
  }
}
