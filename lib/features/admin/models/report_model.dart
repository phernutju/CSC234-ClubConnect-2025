import '../../../models/report_model.dart' as fs;

class ContextMessage {
  final String name;
  final String message;
  final String time;
  final bool isReported;

  const ContextMessage({
    required this.name,
    required this.message,
    required this.time,
    required this.isReported,
  });
}

class AdminReportModel {
  final String id;
  final String aiDetectedLabel;
  final String category;
  final String reportedText;
  final String username;
  final String userDescription;
  final String groupName;
  final String timeAgo;
  final double hateSpeechScore;
  final double harassmentScore;
  final double profanityScore;
  final double threatScore;
  final String source;
  final List<ContextMessage> contextMessages;
  final String targetUserId;

  const AdminReportModel({
    required this.id,
    required this.aiDetectedLabel,
    required this.category,
    required this.reportedText,
    required this.username,
    required this.userDescription,
    required this.groupName,
    required this.timeAgo,
    required this.hateSpeechScore,
    required this.harassmentScore,
    required this.profanityScore,
    required this.threatScore,
    required this.source,
    required this.contextMessages,
    this.targetUserId = '',
  });

  String get severityLabel {
    final scores = [hateSpeechScore, harassmentScore, profanityScore, threatScore];
    final max = scores.reduce((a, b) => a > b ? a : b);
    if (max >= 0.7) return 'HIGH';
    if (max >= 0.4) return 'MEDIUM';
    return 'LOW';
  }

  factory AdminReportModel.fromReportModel(fs.ReportModel r) {
    String timeAgo(DateTime dt) {
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} m';
      if (diff.inHours < 24) return '${diff.inHours} h';
      return '${diff.inDays} d';
    }

    String categoryLabel(fs.ReportReason reason) {
      switch (reason) {
        case fs.ReportReason.hate_speech: return 'Hate Speech';
        case fs.ReportReason.harassment: return 'Harassment';
        case fs.ReportReason.scam: return 'Scam';
        case fs.ReportReason.threat: return 'Threat';
        case fs.ReportReason.other: return 'Other';
      }
    }

    String sourceLabel(fs.ReportSource src) {
      switch (src) {
        case fs.ReportSource.ai_detected: return 'AI Detect';
        case fs.ReportSource.user_ai_detected: return 'AI Detect + User';
        case fs.ReportSource.user: return 'User Report';
      }
    }

    final reason = r.reason;
    return AdminReportModel(
      id: r.reportId.isNotEmpty ? r.reportId : 'R-???',
      aiDetectedLabel: r.source != fs.ReportSource.user ? 'AI detected' : 'User report',
      category: categoryLabel(reason),
      reportedText: '"${r.messageText}"',
      username: r.targetUserId,
      userDescription: 'Reported user',
      groupName: r.communityId,
      timeAgo: timeAgo(r.createdAt),
      hateSpeechScore: reason == fs.ReportReason.hate_speech ? 0.8 : 0.1,
      harassmentScore: reason == fs.ReportReason.harassment ? 0.8 : 0.1,
      profanityScore: 0.0,
      threatScore: reason == fs.ReportReason.threat ? 0.8 : 0.0,
      source: sourceLabel(r.source),
      contextMessages: [],
      targetUserId: r.targetUserId,
    );
  }
}

final List<AdminReportModel> mockReports = const [
  AdminReportModel(
    id: 'R-001',
    aiDetectedLabel: 'AI detected',
    category: 'Hate Speech',
    reportedText: '"Shitty ass gameplay go to hell ggez"',
    username: 'username1',
    userDescription: 'Member of CS Gaming Hub',
    groupName: 'CS Gaming Hub',
    timeAgo: '5 m',
    hateSpeechScore: 0.8,
    harassmentScore: 0.2,
    profanityScore: 0.6,
    threatScore: 0.0,
    source: 'AI Detect + 1 User',
    contextMessages: [
      ContextMessage(name: 'Name1', message: 'consectetuer adipiscing', time: '10:34', isReported: false),
      ContextMessage(name: 'username1', message: 'shitty ass gamepaly go to hell ggez', time: '10:34', isReported: true),
      ContextMessage(name: 'Name2', message: 'What?', time: '10:35', isReported: false),
      ContextMessage(name: 'username1', message: 'shitty ass gamepaly go to hell ggez', time: '10:36', isReported: true),
    ],
  ),
  AdminReportModel(
    id: 'R-002',
    aiDetectedLabel: 'AI detected',
    category: 'Harassment',
    reportedText: '"Stop joining our sessions you worthless noob"',
    username: 'troll_user',
    userDescription: 'Member of Badminton Club',
    groupName: 'Badminton Club',
    timeAgo: '12 m',
    hateSpeechScore: 0.3,
    harassmentScore: 0.85,
    profanityScore: 0.4,
    threatScore: 0.1,
    source: 'AI Detect',
    contextMessages: [
      ContextMessage(name: 'Player1', message: 'Can I join the next match?', time: '14:20', isReported: false),
      ContextMessage(name: 'troll_user', message: 'Stop joining our sessions you worthless noob', time: '14:21', isReported: true),
      ContextMessage(name: 'Player1', message: 'That is really rude...', time: '14:22', isReported: false),
    ],
  ),
  AdminReportModel(
    id: 'R-003',
    aiDetectedLabel: 'AI detected',
    category: 'Spam',
    reportedText: '"BUY COINS NOW!!! BEST PRICE CLICK HERE"',
    username: 'spammer99',
    userDescription: 'New member',
    groupName: 'General Chat',
    timeAgo: '20 m',
    hateSpeechScore: 0.0,
    harassmentScore: 0.1,
    profanityScore: 0.2,
    threatScore: 0.0,
    source: '2 Users',
    contextMessages: [
      ContextMessage(name: 'spammer99', message: 'BUY COINS NOW!!!', time: '09:10', isReported: true),
      ContextMessage(name: 'spammer99', message: 'BEST PRICE CLICK HERE', time: '09:10', isReported: true),
      ContextMessage(name: 'Moderator1', message: 'Please stop spamming', time: '09:11', isReported: false),
    ],
  ),
  AdminReportModel(
    id: 'R-004',
    aiDetectedLabel: 'AI detected',
    category: 'Threat',
    reportedText: '"I know where you live, watch your back"',
    username: 'darkuser42',
    userDescription: 'Member of Coding Club',
    groupName: 'Coding Club',
    timeAgo: '35 m',
    hateSpeechScore: 0.2,
    harassmentScore: 0.5,
    profanityScore: 0.1,
    threatScore: 0.9,
    source: 'AI Detect + 1 User',
    contextMessages: [
      ContextMessage(name: 'CodeFan', message: 'Anyone else submitted the assignment?', time: '11:00', isReported: false),
      ContextMessage(name: 'darkuser42', message: 'I know where you live, watch your back', time: '11:01', isReported: true),
      ContextMessage(name: 'CodeFan', message: 'What the hell...', time: '11:02', isReported: false),
      ContextMessage(name: 'Admin', message: 'This will be reported', time: '11:03', isReported: false),
    ],
  ),
  AdminReportModel(
    id: 'R-005',
    aiDetectedLabel: 'AI detected',
    category: 'Hate Speech',
    reportedText: '"People like you don\'t belong in tech"',
    username: 'gatekeep3r',
    userDescription: 'Member of Dev Society',
    groupName: 'Dev Society',
    timeAgo: '1 h',
    hateSpeechScore: 0.75,
    harassmentScore: 0.6,
    profanityScore: 0.0,
    threatScore: 0.0,
    source: 'AI Detect',
    contextMessages: [
      ContextMessage(name: 'NewDev', message: 'Just started learning Flutter!', time: '08:30', isReported: false),
      ContextMessage(name: 'gatekeep3r', message: 'People like you don\'t belong in tech', time: '08:31', isReported: true),
      ContextMessage(name: 'NewDev', message: 'That is very hurtful', time: '08:32', isReported: false),
      ContextMessage(name: 'Mentor', message: 'Ignore them, you\'re doing great!', time: '08:33', isReported: false),
    ],
  ),
];
