import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/report_model.dart';
import 'admin_report_detail_screen.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});
  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  List<AdminReportModel> reports = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      reports = [
        AdminReportModel(id: 'R-001', aiDetectedLabel: 'AI detected', category: 'Hate Speech', reportedText: '"Shitty ass gameplay go to hell ggez"', username: 'username1', userDescription: 'Description', groupName: 'CS Gaming Hub', timeAgo: 'XX m', hateSpeechScore: 0.8, harassmentScore: 0.2, profanityScore: 0.0, threatScore: 0.0, source: 'AI Detect + 1 User', contextMessages: [ContextMessage(name: 'Name1', message: 'consectetuer adipiscing', time: '10:34', isReported: false), ContextMessage(name: '@username1', message: 'Kuay', time: '10:34', isReported: true), ContextMessage(name: 'Name2', message: 'What?', time: '10:35', isReported: false), ContextMessage(name: '@username1', message: 'Banana head', time: '10:36', isReported: true)]),
        AdminReportModel(id: 'R-002', aiDetectedLabel: 'AI detected', category: 'Harassment', reportedText: '"Stop joining our sessions you worthless noob"', username: 'troll_user', userDescription: 'Description', groupName: 'Badminton Club', timeAgo: 'XX m', hateSpeechScore: 0.3, harassmentScore: 0.9, profanityScore: 0.1, threatScore: 0.0, source: 'AI Detect', contextMessages: [ContextMessage(name: 'Name1', message: 'Good session today', time: '10:00', isReported: false), ContextMessage(name: '@troll_user', message: 'Stop joining our sessions', time: '10:01', isReported: true)]),
        AdminReportModel(id: 'R-003', aiDetectedLabel: 'AI detected', category: 'Spam', reportedText: '"BUY COINS NOW!!! BEST PRICE CLICK HERE"', username: 'spammer99', userDescription: 'Description', groupName: 'General', timeAgo: 'XX m', hateSpeechScore: 0.0, harassmentScore: 0.0, profanityScore: 0.0, threatScore: 0.0, source: 'AI Detect + 2 Users', contextMessages: [ContextMessage(name: '@spammer99', message: 'BUY COINS NOW!!!', time: '09:00', isReported: true)]),
        AdminReportModel(id: 'R-004', aiDetectedLabel: 'AI detected', category: 'Threat', reportedText: '"I know where you live, watch your back"', username: 'darkuser42', userDescription: 'Description', groupName: 'Coding Club', timeAgo: 'XX m', hateSpeechScore: 0.2, harassmentScore: 0.5, profanityScore: 0.0, threatScore: 0.9, source: 'AI Detect + 1 User', contextMessages: [ContextMessage(name: 'Name1', message: 'Nice code!', time: '14:00', isReported: false), ContextMessage(name: '@darkuser42', message: 'I know where you live', time: '14:01', isReported: true)]),
        AdminReportModel(id: 'R-005', aiDetectedLabel: 'AI detected', category: 'Hate Speech', reportedText: '"People like you don\'t belong in tech"', username: 'gatekeep3r', userDescription: 'Description', groupName: 'Dev Society', timeAgo: 'XX m', hateSpeechScore: 0.7, harassmentScore: 0.4, profanityScore: 0.0, threatScore: 0.0, source: 'AI Detect', contextMessages: [ContextMessage(name: 'Name1', message: 'Anyone uses Flutter?', time: '11:00', isReported: false), ContextMessage(name: '@gatekeep3r', message: 'People like you don\'t belong in tech', time: '11:01', isReported: true)]),
        AdminReportModel(id: 'R-006', aiDetectedLabel: 'AI detected', category: 'Harassment', reportedText: '"Nobody wants you here, just leave"', username: 'toxic_99', userDescription: 'Description', groupName: 'Running Club', timeAgo: 'XX m', hateSpeechScore: 0.2, harassmentScore: 0.85, profanityScore: 0.1, threatScore: 0.0, source: 'AI Detect + 2 Users', contextMessages: [ContextMessage(name: 'Name1', message: 'Great run today!', time: '09:10', isReported: false), ContextMessage(name: '@toxic_99', message: 'Nobody wants you here', time: '09:11', isReported: true)]),
        AdminReportModel(id: 'R-007', aiDetectedLabel: 'AI detected', category: 'Threat', reportedText: '"You will regret posting that"', username: 'shadow_x', userDescription: 'Description', groupName: 'Photography Club', timeAgo: 'XX m', hateSpeechScore: 0.1, harassmentScore: 0.3, profanityScore: 0.0, threatScore: 0.8, source: 'AI Detect + 1 User', contextMessages: [ContextMessage(name: 'Name1', message: 'Love this photo!', time: '14:20', isReported: false), ContextMessage(name: '@shadow_x', message: 'You will regret posting that', time: '14:21', isReported: true)]),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF1A1A1A),
            padding: EdgeInsets.fromLTRB(20, topPad + MediaQuery.of(context).size.height * 0.03, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trust & Safety', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF797979))),
                      Text('Reports Queue', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w400, color: Colors.white)),
                    ],
                  ),
                ),
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: const Color(0xFFE8A598), borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('.claude/usericon.png', fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(child: Text('🙂', style: TextStyle(fontSize: 32)))),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final r = reports[index];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminReportDetailScreen(report: r))),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFE8DFD8), borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFFFE5A0), borderRadius: BorderRadius.circular(20)),
                              child: Text('AI detected', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.black)),
                            ),
                            const SizedBox(width: 8),
                            Text(r.category, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.black)),
                            const Spacer(),
                            Text(r.timeAgo, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w300, color: const Color(0xFF797979))),
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
                                    width: 20,
                                    color: const Color(0xFFFF6B6B),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Text(r.reportedText, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black)),
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
                            const CircleAvatar(radius: 22, backgroundColor: Color(0xFFE8A598)),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('@${r.username}', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black)),
                                Text(r.userDescription, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF797979))),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
              decoration: BoxDecoration(color: const Color(0xFFFF6B4A), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 4),
            Text('Reports', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFFFF6B4A))),
          ],
        ),
      ),
    );
  }
}
