import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/profile_args.dart';
import '../../../models/report_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/report_provider.dart';
import '../../../services/user_service.dart';
import '../models/report_model.dart';
import 'admin_report_detail_screen.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                          Text('Admin Panel',
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
                        errorBuilder: (_, __, ___) => const Center(
                            child: Text('🙂', style: TextStyle(fontSize: 32))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFFF6B4A),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF797979),
                  labelStyle: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w400),
                  tabs: const [
                    Tab(text: 'Reports'),
                    Tab(text: 'Muted'),
                    Tab(text: 'Banned'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ReportsTab(),
                _MutedUsersTab(),
                _BannedUsersTab(),
              ],
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
              child: const Icon(Icons.shield_outlined,
                  color: Colors.white, size: 26),
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

class _ReportsTab extends StatefulWidget {
  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  final Map<String, AdminReportModel> _enriched = {};
  final Set<String> _enriching = {};

  void _enrichAll(List<AdminReportModel> base) {
    for (final r in base) {
      if (!_enriched.containsKey(r.id) && !_enriching.contains(r.id)) {
        _enriching.add(r.id);
        _enrichSingle(r);
      }
    }
  }

  Future<void> _enrichSingle(AdminReportModel base) async {
    try {
      final targetInfoF = UserService.getUserInfo(base.targetUserId);
      final reporterInfoF = UserService.getUserInfo(base.reporterId);
      final communityF = UserService.getCommunityName(base.communityId);
      final targetInfo = await targetInfoF;
      final reporterInfo = await reporterInfoF;
      final communityName = await communityF;
      final enriched = base.copyWithEnrichment(
        displayName: targetInfo.displayName.isNotEmpty
            ? targetInfo.displayName
            : base.targetUserId,
        photoURL: targetInfo.photoURL,
        reporterDisplayName: reporterInfo.displayName.isNotEmpty
            ? reporterInfo.displayName
            : base.reporterId,
        reporterPhotoUrl: reporterInfo.photoURL,
        communityName:
            communityName.isNotEmpty ? communityName : base.communityId,
      );
      if (mounted) {
        setState(() {
          _enriched[base.id] = enriched;
          _enriching.remove(base.id);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _enriched[base.id] = base;
          _enriching.remove(base.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReportModel>>(
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
        final baseReports = firestoreReports
            .map((r) => AdminReportModel.fromReportModel(r))
            .toList();

        _enrichAll(baseReports);

        final reports = baseReports.map((r) => _enriched[r.id] ?? r).toList();

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
                  color: r.status == 'urgent'
                      ? const Color(0xFFFFE5E5)
                      : const Color(0xFFE8DFD8),
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
                            color: r.aiDetectedLabel == 'AI detected'
                                ? const Color(0xFFFFE5A0)
                                : const Color(0xFFFF6B4A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(r.aiDetectedLabel,
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: r.aiDetectedLabel == 'AI detected'
                                      ? Colors.black
                                      : Colors.white)),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4444),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('URGENT',
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
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
                              Container(
                                  width: 20, color: const Color(0xFFFF6B6B)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
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
                        _buildAvatar(r.targetUserPhotoURL, radius: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: r.targetUserId.isNotEmpty
                                    ? () => context.push('/other-profile',
                                        extra: ProfileArgs(
                                          userId: r.targetUserId,
                                          username: r.username,
                                          communityName: r.groupName,
                                          communityId: r.communityId,
                                        ))
                                    : null,
                                child: Text('@${r.username}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: r.targetUserId.isNotEmpty
                                            ? const Color(0xFFFF6B4A)
                                            : Colors.black,
                                        decoration: r.targetUserId.isNotEmpty
                                            ? TextDecoration.underline
                                            : null),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text(r.groupName,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF797979))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvatar(String photoURL, {double radius = 22}) {
    if (photoURL.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(photoURL),
        backgroundColor: const Color(0xFFE8A598),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE8A598),
      child: Icon(Icons.person, color: Colors.white, size: radius),
    );
  }
}

class _MutedUsersTab extends StatelessWidget {
  String _formatExpiry(dynamic ts) {
    if (ts == null) return 'Unknown';
    final dt = (ts as Timestamp).toDate();
    final remaining = dt.difference(DateTime.now());
    if (remaining.isNegative) return 'Expiring soon';
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m remaining' : '${m}m remaining';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: UserService.streamMutedUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B4A)));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: GoogleFonts.poppins(color: Colors.red)));
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return Center(
              child: Text('No muted users',
                  style: GoogleFonts.poppins(
                      fontSize: 16, color: const Color(0xFF797979))));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final u = users[index];
            final uid = u['uid'] as String? ?? '';
            final username =
                u['username'] as String? ?? u['displayName'] as String? ?? uid;
            final muteCount = (u['muteCount'] as int?) ?? 1;
            final expiry = _formatExpiry(u['muteExpiresAt']);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFFFB74D),
                    child: Icon(Icons.volume_off, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('@$username',
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('Mute #$muteCount • $expiry',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: const Color(0xFF797979))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _UnbanButton(userId: uid),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _BannedUsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: UserService.streamBannedUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B4A)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          );
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(
            child: Text(
              'No banned users',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF797979),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final u = users[index];
            final uid = u['uid'] as String? ?? '';
            final username =
                u['username'] as String? ?? u['displayName'] as String? ?? uid;
            final reason = u['banReason'] as String? ?? 'No reason given';
            final duration = u['durationLabel'] as String? ?? 'Permanently';

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5E5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFE8A598),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@$username',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Reason: $reason',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF797979),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Duration: $duration',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF797979),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _UnbanButton(userId: uid),
                ],
              ),
            );
          },
        );
      },
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
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF4CAF50)),
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
