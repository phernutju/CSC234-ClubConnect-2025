import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/report_model.dart' as fs;
import '../../../providers/report_provider.dart';
import '../models/report_model.dart';
import '../widgets/ban_popup.dart';

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: _SeverityRow(report: report),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'AI Analysis',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF797979),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _AiAnalysisCard(report: report),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Context',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF797979),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ContextCard(messages: report.contextMessages),
                  const SizedBox(height: 16),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomActions(report: report),
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
            color: const Color(0xFFFF6B4A),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'Reported',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE5A0),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            report.aiDetectedLabel,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF000000),
            ),
          ),
        ),
      ],
    );
  }
}

class _AiAnalysisCard extends StatelessWidget {
  final AdminReportModel report;
  const _AiAnalysisCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD8), width: 1),
      ),
      child: Column(
        children: [
          if (report.description.isNotEmpty && report.source.contains('AI'))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'AI reason: ${report.description}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF797979),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          _ScoreRow(label: 'Hate Speech', score: report.hateSpeechScore),
          const SizedBox(height: 10),
          _ScoreRow(label: 'Harassment', score: report.harassmentScore),
          const SizedBox(height: 10),
          _ScoreRow(label: 'Profanity', score: report.profanityScore),
          const SizedBox(height: 10),
          _ScoreRow(label: 'Threat', score: report.threatScore),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final double score;
  const _ScoreRow({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF000000))),
            Text(score.toStringAsFixed(1), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF000000))),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFE8D5CE),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            FractionallySizedBox(
              widthFactor: score,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B4A),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContextCard extends StatelessWidget {
  final List<ContextMessage> messages;
  const _ContextCard({required this.messages});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8DFD8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < messages.length; i++) ...[
            if (i != 0) const SizedBox(height: 16),
            _ChatBubble(msg: messages[i]),
          ],
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ContextMessage msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final nameColor =
        msg.isReported ? const Color(0xFFFF6B4A) : const Color(0xFF000000);
    final displayName = msg.isReported ? '@${msg.name}' : msg.name;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFE8A598),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: nameColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    msg.time,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: const Color(0xFF797979),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.6,
                ),
                child: IntrinsicWidth(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      border: msg.isReported
                          ? Border.all(
                              color: const Color(0xFFFF6B4A), width: 1)
                          : null,
                    ),
                    child: Text(
                      msg.message,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF000000),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _BottomActions extends StatelessWidget {
  final AdminReportModel report;
  const _BottomActions({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () async {
                final reportProvider = context.read<ReportProvider>();
                await reportProvider.updateReportStatus(report.id, fs.ReportStatus.reviewed);
                if (context.mounted) Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.transparent,
              ),
              child: Text(
                'Dismiss',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => BanPopup(report: report),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6868),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
              ),
              child: Text(
                'Ban [${report.username}]',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
