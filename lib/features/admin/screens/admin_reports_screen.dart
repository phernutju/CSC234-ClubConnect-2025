import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/report_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/report_provider.dart';
import '../../../services/user_service.dart';
import '../models/report_model.dart';
import 'admin_report_detail_screen.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AppAuthProvider>().role;
    if (role != 'admin') {
      return const Scaffold(
        body: Center(
          child: Text(
            'Access Denied',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF1A1A1A),
            padding: EdgeInsets.fromLTRB(
              20,
              topPad + MediaQuery.of(context).size.height * 0.03,
              20,
              16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trust & Safety',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF797979))),
                      Text('Reports Queue',
                          style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                              color: Colors.white)),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8A598),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    '.claude/usericon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Center(child: Text('🙂', style: TextStyle(fontSize: 32))),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ReportModel>>(
              stream: context.read<ReportProvider>().pendingReportsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6B4A)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading reports: ${snapshot.error}',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  );
                }

                final firestoreReports = snapshot.data ?? [];
                final reports = firestoreReports
                    .map((r) => AdminReportModel.fromReportModel(r))
                    .toList();

                if (reports.isEmpty) {
                  return Center(
                    child: Text(
                      'No pending reports',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF797979),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final r = reports[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminReportDetailScreen(report: r),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: r.status == 'urgent' ? const Color(0xFFFFE5E5) : const Color(0xFFE8DFD8),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE5A0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(r.aiDetectedLabel,
                                      style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black)),
                                ),
                                const SizedBox(width: 8),
                                Text(r.category,
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black)),
                                if (r.status == 'urgent')
                                  Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF4444),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('URGENT',
                                        style: GoogleFonts.poppins(
                                            fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ),
                                const Spacer(),
                                Text(r.timeAgo,
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w300,
                                        color: const Color(0xFF797979))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: Colors.white,
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Container(width: 20, color: const Color(0xFFFF6B6B)),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          child: Text(r.reportedText,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.black)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Color(0xFFE8A598)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('@${r.username}',
                                          style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      Text(r.source,
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: const Color(0xFF797979))),
                                    ],
                                  ),
                                ),
                                if (r.targetUserId.isNotEmpty)
                                  _UnbanButton(userId: r.targetUserId),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF1A1A1A),
        padding: EdgeInsets.only(top: 10, bottom: bottomPad + 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B4A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 4),
            Text('Reports',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFFF6B4A))),
          ],
        ),
      ),
    );
  }
}

class _UnbanButton extends StatefulWidget {
  final String userId;
  const _UnbanButton({required this.userId});

  @override
  State<_UnbanButton> createState() => _UnbanButtonState();
}

class _UnbanButtonState extends State<_UnbanButton> {
  bool _loading = false;

  Future<void> _onUnban() async {
    setState(() => _loading = true);
    try {
      await UserService.unbanUser(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User has been unbanned.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unban: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _onUnban,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4CAF50)),
        ),
        child: _loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4CAF50)),
              )
            : Text(
                'Unban',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2E7D32),
                ),
              ),
      ),
    );
  }
}
