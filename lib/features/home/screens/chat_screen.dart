import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/chat_args.dart';
import '../../../models/message_model.dart';
import '../../../models/profile_args.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/community_provider.dart';
import '../widgets/community_info_modal.dart';
import '../widgets/members_sheet.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';
import '../widgets/message_long_press_menu.dart';
import '../widgets/report_message_modal.dart';

class _SystemEntry {
  final int insertAfter; // insert after this many Firestore messages
  final ChatMessage message;
  _SystemEntry(this.insertAfter, this.message);
}

class ChatScreen extends StatefulWidget {
  final String communityId;
  final String communityName;
  final String memberCount;
  final String? targetMessageId;

  const ChatScreen({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.memberCount,
    this.targetMessageId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  ChatMessage? _replyingTo;
  bool _isSending = false;
  bool _isInitializing = true;
  bool _menuOpen = false;

  final List<_SystemEntry> _systemMessages = [];

  // Ban state
  bool _isBanned = false;
  bool _isMuted = false;
  DateTime? _muteExpiresAt;
  StreamSubscription<DocumentSnapshot>? _banSub;
  Timer? _muteTimer;

  // Mention autocomplete
  String? _mentionQuery;
  final Map<String, String> _pendingMentions = {};

  final Set<String> _fetchedUids = {};
  CommunityProvider? _provider;
  int _lastMessageCount = 0;

  // Target-message scroll/highlight (e.g. tap from a reply/mention notification)
  String? _pendingScrollTargetId;
  String? _highlightedMessageId;
  Timer? _highlightTimer;
  final Map<String, GlobalKey> _messageKeys = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider ??= context.read<CommunityProvider>();
  }

  @override
  void initState() {
    super.initState();
    _pendingScrollTargetId = widget.targetMessageId;
    _inputController.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final cp = context.read<CommunityProvider>();
      _provider = cp;
      _provider!.addListener(_onProviderChange);
      if (widget.communityId.isEmpty) {
        setState(() => _isInitializing = false);
        return;
      }
      final community = await cp.fetchCommunity(widget.communityId);
      if (!mounted) return;
      if (community != null) cp.setActiveCommunity(community);
      setState(() => _isInitializing = false);
      _startBanWatch();
    });
  }

  void _startBanWatch() {
    final uid = context.read<AppAuthProvider>().user?.uid ?? '';
    if (uid.isEmpty) return;
    _banSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      if (!mounted || !snap.exists) return;
      final data = snap.data()!;
      final banned = (data['isBanned'] as bool?) ?? false;
      final muted = (data['isMuted'] as bool?) ?? false;
      final muteTs = data['muteExpiresAt'] as Timestamp?;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _isBanned = banned;
          _isMuted = muted;
          _muteExpiresAt = muteTs?.toDate();
        });
        if (muted) {
          _muteTimer?.cancel();
          _muteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
            if (mounted) setState(() {});
          });
        } else {
          _muteTimer?.cancel();
          _muteTimer = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderChange);
    _banSub?.cancel();
    _muteTimer?.cancel();
    _provider?.clearActiveCommunity();
    _highlightTimer?.cancel();
    _inputController.removeListener(_onTextChanged);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onProviderChange() {
    final warning = _provider?.violationWarning;
    if (warning != null && mounted) {
      _provider?.violationWarning = null; // clear before showing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(warning),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }
  }

  // ── Mention detection ────────────────────────────────────────────────────────

  void _onTextChanged() {
    final text = _inputController.text;
    final cursor = _inputController.selection.baseOffset;
    if (cursor <= 0) {
      if (_mentionQuery != null) setState(() => _mentionQuery = null);
      return;
    }

    final textBeforeCursor = text.substring(0, cursor);
    final lastAt = textBeforeCursor.lastIndexOf('@');
    if (lastAt < 0) {
      if (_mentionQuery != null) setState(() => _mentionQuery = null);
      return;
    }

    final fragment = textBeforeCursor.substring(lastAt + 1);
    if (fragment.contains(' ')) {
      if (_mentionQuery != null) setState(() => _mentionQuery = null);
      return;
    }

    if (_mentionQuery != fragment) setState(() => _mentionQuery = fragment);
  }

  void _onMentionSelected(String displayName, String uid) {
    final text = _inputController.text;
    final cursor = _inputController.selection.baseOffset.clamp(0, text.length);
    final lastAt = text.lastIndexOf('@', cursor);
    if (lastAt < 0) return;

    final before = text.substring(0, lastAt);
    final after = text.substring(cursor);
    final inserted = '@$displayName ';
    _inputController.value = TextEditingValue(
      text: '$before$inserted$after',
      selection: TextSelection.collapsed(offset: before.length + inserted.length),
    );
    _pendingMentions[displayName] = uid;
    setState(() => _mentionQuery = null);
  }

  List<({String uid, String displayName})> _buildSuggestions(CommunityProvider cp, String currentUid) {
    final q = _mentionQuery;
    if (q == null) return [];

    final results = <({String uid, String displayName})>[];
    for (final m in cp.members) {
      if (m.userId == currentUid) continue;
      final name = cp.displayNameOf(m.userId);
      if (name.isEmpty) continue;
      if (q.isEmpty || name.toLowerCase().contains(q.toLowerCase())) {
        results.add((uid: m.userId, displayName: name));
      }
    }
    return results;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  ChatMessage _toUIMessage(MessageModel m, String currentUid, CommunityProvider cp) {
    if (m.isSystem) {
      return ChatMessage(
        id: m.id,
        text: m.text,
        isSent: false,
        senderName: m.senderName,
        senderId: m.senderId,
        timestamp: m.timestamp,
        time: _formatTime(m.timestamp),
        isSystemMessage: true,
        type: m.type,
      );
    }
    final isSent = m.senderId == currentUid;
    final cachedName = cp.displayNameOf(m.senderId);
    final fallback = m.senderName.isNotEmpty ? m.senderName : '…';
    final senderName = isSent ? 'You' : (cachedName.isNotEmpty ? cachedName : fallback);

    final mentionMap = <String, String>{};
    for (final uid in m.mentions) {
      final name = cp.displayNameOf(uid);
      if (name.isNotEmpty) mentionMap[name] = uid;
    }

    return ChatMessage(
      id: m.id,
      text: m.text,
      imageUrl: m.imageURL.isNotEmpty ? m.imageURL : null,
      isSent: isSent,
      senderName: senderName,
      senderId: m.senderId,
      timestamp: m.timestamp,
      time: _formatTime(m.timestamp),
      readCount: isSent ? 'Read ${m.seenBy.length}' : null,
      replyToName: m.replyToSenderName,
      replyToText: m.replyToText,
      mentionMap: mentionMap,
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> _sendTextMessage() async {
    if (widget.communityId.isEmpty) return;
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending || _isBanned) return;
    if (_isMuted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have been restricted from sending messages.')),
      );
      return;
    }

    final replySnapshot = _replyingTo;
    final mentionUids = List<String>.from(_pendingMentions.values);

    _inputController.clear();
    setState(() {
      _isSending = true;
      _replyingTo = null;
      _mentionQuery = null;
      _pendingMentions.clear();
    });

    try {
      await context.read<CommunityProvider>().sendMessage(
            widget.communityId,
            text: text,
            replyToId: replySnapshot?.id,
            replyToSenderName: replySnapshot?.senderName,
            replyToText: replySnapshot?.text,
            replyToSenderId: replySnapshot?.senderId,
            mentions: mentionUids,
          );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
      setState(() => _replyingTo = replySnapshot);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _sendImageMessage(Uint8List bytes) => _doSendImage(bytes);

  Future<void> _doSendImage(Uint8List bytes) async {
    setState(() => _isSending = true);
    try {
      await context.read<CommunityProvider>().sendImageMessage(widget.communityId, bytes);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _sendSystemMessage(String text) {
    if (!mounted) return;
    setState(() {
      _systemMessages.add(_SystemEntry(
        context.read<CommunityProvider>().messages.length,
        ChatMessage(
          id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
          text: text,
          isSent: false,
          senderName: '',
          senderId: 'system',
          timestamp: DateTime.now(),
          time: _formatTime(DateTime.now()),
          isSystemMessage: true,
        ),
      ));
    });
  }

  List<ChatMessage> _mergeSystemMessages(List<ChatMessage> base) {
    if (_systemMessages.isEmpty) return base;
    final result = List<ChatMessage>.from(base);
    // Insert in reverse position order so earlier inserts don't shift later ones
    final sorted = [..._systemMessages]
      ..sort((a, b) => b.insertAfter.compareTo(a.insertAfter));
    for (final entry in sorted) {
      final pos = entry.insertAfter.clamp(0, result.length);
      result.insert(pos, entry.message);
    }
    return result;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToTargetMessage() {
    final id = _pendingScrollTargetId;
    if (id == null) return;
    final key = _messageKeys[id];
    final ctx = key?.currentContext;
    if (ctx == null) return; // not laid out yet — try again on next frame
    _pendingScrollTargetId = null;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0.3,
    );
    setState(() => _highlightedMessageId = id);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _highlightedMessageId = null);
    });
  }

  void _onLongPressMessage(ChatMessage message, Offset tapPosition) {
    showMessageMenu(
      context,
      message: message,
      tapPosition: tapPosition,
      onReply: () => setState(() => _replyingTo = message),
      onReport: () => showReportModal(
        context,
        reportedUsername: message.senderName,
        communityName: widget.communityName,
        messageSnippet: message.text,
        reporterId: context.read<AppAuthProvider>().user?.uid ?? '',
        targetUserId: message.senderId,
        communityId: widget.communityId,
        messageId: message.id,
      ),
      onDelete: () => context
          .read<CommunityProvider>()
          .deleteMessage(widget.communityId, message.id),
    );
  }

  void _onMentionTap(String uid, String currentUid, CommunityProvider cp) {
    if (uid == currentUid) return;
    final name = cp.displayNameOf(uid);
    context.push(
      '/other-profile',
      extra: ProfileArgs(
        userId: uid,
        username: name.isNotEmpty ? name : uid,
        communityName: widget.communityName,
        communityId: widget.communityId,
      ),
    );
  }

  void _onInfo() {
    setState(() => _menuOpen = false);
    final cp = context.read<CommunityProvider>();
    final community = cp.activeCommunity;
    if (community == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.chatInfoSnackbar)),
      );
      return;
    }

    final currentUid = context.read<AppAuthProvider>().user?.uid ?? '';
    final isHost = community.createdBy == currentUid;

    if (isHost) {
      context.push('/edit-community', extra: community);
    } else {
      showDialog(
        context: context,
        barrierColor: Colors.black45,
        barrierDismissible: true,
        builder: (_) => CommunityInfoModal(community: community),
      );
    }
  }

  void _onMute() {
    setState(() => _menuOpen = false);
    final provider = context.read<CommunityProvider>();
    provider.toggleMute(widget.communityId);
    final nowMuted = provider.isMuted(widget.communityId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowMuted ? AppStrings.chatMutedSnackbar : AppStrings.chatUnmutedSnackbar,
        ),
      ),
    );
  }


  void _onLeave() {
    setState(() => _menuOpen = false);
    showDialog(
      context: context,
      builder: (ctx) => _LeaveDialog(
        onNo: () => Navigator.of(ctx).pop(),
        onYes: () async {
          Navigator.of(ctx).pop();
          await context.read<CommunityProvider>().leaveCommunity(widget.communityId);
          if (mounted) context.go('/home');
        },
      ),
    );
  }

  void _onShowMembers() {
    setState(() => _menuOpen = false);
    final cp = context.read<CommunityProvider>();
    final community = cp.communities.where((c) => c.id == widget.communityId).firstOrNull;
    final currentUid = context.read<AppAuthProvider>().user?.uid ?? '';
    showMembersBottomSheet(
      context,
      communityId: widget.communityId,
      communityName: widget.communityName,
      currentUid: currentUid,
      creatorId: community?.createdBy ?? '',
      onSystemMessage: _sendSystemMessage,
    );
  }

  void _onEvents() {
    setState(() => _menuOpen = false);
    final cp = context.read<CommunityProvider>();
    final memberCount = cp.members.isNotEmpty
        ? cp.members.length.toString()
        : widget.memberCount;
    context.push(
      '/events',
      extra: ChatArgs(
        communityId: widget.communityId,
        communityName: widget.communityName,
        memberCount: memberCount,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final cp = context.watch<CommunityProvider>();
    final currentUid = context.watch<AppAuthProvider>().user?.uid ?? '';
    final muted = cp.isMuted(widget.communityId);
    final myRole = cp.members
        .where((m) => m.userId == currentUid)
        .map((m) => m.role)
        .fold<String>('user', (_, r) => r);
    // Trigger display-name fetches for message senders
    for (final m in cp.messages) {
      if (!m.isSystem && m.senderId != currentUid && _fetchedUids.add(m.senderId)) {
        cp.fetchDisplayName(m.senderId);
      }
    }

    // Trigger display-name fetches for all members (needed for autocomplete)
    if (_mentionQuery != null) {
      for (final m in cp.members) {
        if (m.userId != currentUid && _fetchedUids.add(m.userId)) {
          cp.fetchDisplayName(m.userId);
        }
      }
    }

    // Trigger display-name fetches for mentioned UIDs in messages
    for (final m in cp.messages) {
      for (final uid in m.mentions) {
        if (_fetchedUids.add(uid)) cp.fetchDisplayName(uid);
      }
    }

    if (cp.messages.length != _lastMessageCount) {
      _lastMessageCount = cp.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pendingScrollTargetId != null) {
          _scrollToTargetMessage();
        } else {
          _scrollToBottom();
        }
      });
    } else if (_pendingScrollTargetId != null) {
      // Messages already loaded (e.g. cached) on first build — still try.
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTargetMessage());
    }

    final uiMessages = _mergeSystemMessages(
      cp.messages.map((m) => _toUIMessage(m, currentUid, cp)).toList(),
    );

    final memberDisplay = cp.members.isNotEmpty
        ? cp.members.length.toString()
        : widget.memberCount;
    final suggestions = _buildSuggestions(cp, currentUid);

    return Scaffold(
      backgroundColor: AppColors.chatBackground,
      body: Stack(
        children: [
          // ── Main content column ──────────────────────────────────────────
          Column(
            children: [
              // ── App bar ──────────────────────────────────────────────────
              _ChatAppBar(
                communityName: widget.communityName,
                memberCount: memberDisplay,
                onMenuTap: () => setState(() => _menuOpen = !_menuOpen),
              ),

              // ── Error banner ────────────────────────────────────────────
              if (cp.error != null)
                _ErrorBanner(message: cp.error!),

              // ── Upload progress ─────────────────────────────────────────
              if (cp.isUploading || _isSending)
                const LinearProgressIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.inputFill,
                ),

              // ── Message list ────────────────────────────────────────────
              Expanded(child: _buildMessageList(uiMessages, cp, currentUid)),

              // ── Mention autocomplete bar ─────────────────────────────────
              if (suggestions.isNotEmpty)
                _MentionSuggestionsBar(
                  suggestions: suggestions,
                  onSelect: _onMentionSelected,
                ),

              // ── Ban banner ───────────────────────────────────────────────
              if (_isBanned) const _BanBanner(),

              // ── Mute banner ──────────────────────────────────────────────
              if (_isMuted && !_isBanned)
                _MuteBanner(muteExpiresAt: _muteExpiresAt),

              // ── Input bar ────────────────────────────────────────────────
              MessageInputBar(
                controller: _inputController,
                onSend: _sendTextMessage,
                onImagePicked: _sendImageMessage,
                replyToName: _replyingTo?.senderName,
                replyToText: _replyingTo?.text,
                onCancelReply: () => setState(() => _replyingTo = null),
                enabled: !_isBanned,
              ),
            ],
          ),

          // ── Dismissal barrier (shown when menu is open) ──────────────────
          if (_menuOpen)
            Positioned(
              top: statusBarHeight + AppSizes.appBarHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => setState(() => _menuOpen = false),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),

          // ── Drop-down menu bar ───────────────────────────────────────────
          if (_menuOpen)
            Positioned(
              top: statusBarHeight + AppSizes.appBarHeight,
              left: 0,
              right: 0,
              child: _ChatMenuBar(
                muted: muted,
                onInfo: _onInfo,
                onMute: _onMute,
                onLeave: _onLeave,
                onShowMembers: _onShowMembers,
                onEvents: _onEvents,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> uiMessages, CommunityProvider cp, String currentUid) {
    if (_isInitializing || (cp.isLoading && cp.messages.isEmpty)) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (cp.messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Say hello! 👋',
          style: AppTextStyles.body(color: AppColors.textGray),
        ),
      );
    }

    final items = _buildItems(uiMessages);
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.paddingM),
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is String) return _DateSeparator(label: item);
        final message = item as ChatMessage;

        final isTargetMessage = widget.targetMessageId != null &&
            message.id == widget.targetMessageId;
        final key = isTargetMessage
            ? _messageKeys.putIfAbsent(message.id, () => GlobalKey())
            : null;
        final isHighlighted = message.id == _highlightedMessageId;

        final bubble = MessageBubble(
          message: message,
          onLongPress: (pos) => _onLongPressMessage(message, pos),
          onSenderTap: message.isSent
              ? null
              : () => context.push(
                    '/other-profile',
                    extra: ProfileArgs(
                      userId: message.senderId,
                      username: message.senderName,
                      communityName: widget.communityName,
                      communityId: widget.communityId,
                    ),
                  ),
          onMentionTap: (uid) => _onMentionTap(uid, currentUid, cp),
        );

        return AnimatedContainer(
          key: key,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingXS,
            vertical: AppSizes.paddingXS,
          ),
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusBubbleTail),
          ),
          child: bubble,
        );
      },
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _MentionSuggestionsBar extends StatelessWidget {
  final List<({String uid, String displayName})> suggestions;
  final void Function(String displayName, String uid) onSelect;

  const _MentionSuggestionsBar({required this.suggestions, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(top: BorderSide(color: AppColors.rateCardBorder)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, -2)),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (context, i) {
          final s = suggestions[i];
          return ListTile(
            dense: true,
            leading: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.avatarSalmon,
              ),
            ),
            title: Text(
              s.displayName,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontSM,
                color: AppColors.textDark,
              ),
            ),
            onTap: () => onSelect(s.displayName, s.uid),
          );
        },
      ),
    );
  }
}

class _BanBanner extends StatelessWidget {
  const _BanBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: AppSizes.banBannerHeight),
      decoration: BoxDecoration(
        color: AppColors.banBannerBg,
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, -2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingXS,
      ),
      child: Text(
        AppStrings.banText,
        textAlign: TextAlign.center,
        style: AppTextStyles.body(
          fontSize: AppSizes.fontXXS,
          fontWeight: FontWeight.w300,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}

class _MuteBanner extends StatelessWidget {
  final DateTime? muteExpiresAt;
  const _MuteBanner({this.muteExpiresAt});

  String _formatRemaining() {
    if (muteExpiresAt == null) return 'Temporarily muted';
    final remaining = muteExpiresAt!.difference(DateTime.now());
    if (remaining.isNegative) return 'Mute expiring soon...';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    if (hours > 0) return 'Muted • ${hours}h ${minutes}m remaining';
    return 'Muted • ${minutes}m remaining';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFF9800),
        boxShadow: [
          BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, -2)),
        ],
      ),
      child: Text(
        _formatRemaining(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget {
  final String communityName;
  final String memberCount;
  final VoidCallback onMenuTap;

  const _ChatAppBar({
    required this.communityName,
    required this.memberCount,
    required this.onMenuTap,
  });

  String get _title =>
      memberCount.isEmpty ? communityName : '$communityName ($memberCount)';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: AppSizes.paddingM,
        right: AppSizes.paddingM,
      ),
      child: SizedBox(
        height: AppSizes.appBarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => context.go('/home'),
              child: const Icon(Icons.arrow_back, color: AppColors.cardWhite),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
              child: Text(
                _title,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(
                  fontSize: AppSizes.fontL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cardWhite,
                ),
              ),
            ),
            GestureDetector(
              onTap: onMenuTap,
              child: const Icon(Icons.menu, color: AppColors.cardWhite),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dateLabel(DateTime date) {
  final now = DateTime.now();
  if (_isSameDay(date, now)) return 'Today';
  if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  if (date.year == now.year) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

List<Object> _buildItems(List<ChatMessage> messages) {
  final items = <Object>[];
  DateTime? lastDate;
  for (final msg in messages) {
    if (lastDate == null || !_isSameDay(lastDate, msg.timestamp)) {
      items.add(_dateLabel(msg.timestamp));
      lastDate = msg.timestamp;
    }
    items.add(msg);
  }
  return items;
}

class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: AppTextStyles.body(fontSize: AppSizes.fontXS, color: AppColors.textGray),
      ),
    );
  }
}

class _ChatMenuBar extends StatelessWidget {
  final bool muted;
  final VoidCallback onInfo;
  final VoidCallback onMute;
  final VoidCallback onLeave;
  final VoidCallback onShowMembers;
  final VoidCallback onEvents;

  const _ChatMenuBar({
    required this.muted,
    required this.onInfo,
    required this.onMute,
    required this.onLeave,
    required this.onShowMembers,
    required this.onEvents,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _MenuItem(
                  icon: muted ? Icons.notifications_off : Icons.notifications_off_outlined,
                  label: muted ? AppStrings.chatMenuUnmute : AppStrings.chatMenuMute,
                  onTap: onMute,
                ),
                const SizedBox(height: 5),
                _MenuItem(icon: Icons.description_outlined, label: AppStrings.chatMenuInfo, onTap: onInfo),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _MenuItem(icon: Icons.group_outlined, label: AppStrings.chatMenuMembers, onTap: onShowMembers),
                const SizedBox(height: 5),
                _MenuItem(icon: Icons.local_activity, label: AppStrings.chatMenuEvents, onTap: onEvents),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _MenuItem(icon: Icons.exit_to_app, label: AppStrings.chatMenuLeave, onTap: onLeave),
                const SizedBox(height: 5),
                const SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveDialog extends StatelessWidget {
  final VoidCallback onNo;
  final VoidCallback onYes;

  const _LeaveDialog({required this.onNo, required this.onYes});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSizes.rateModalRadius),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.paddingL,
          AppSizes.paddingL,
          AppSizes.paddingL,
          AppSizes.paddingM,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.chatLeaveTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.poppins(
                fontSize: AppSizes.fontSM,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppSizes.paddingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DialogButton(label: AppStrings.chatLeaveNo, color: AppColors.commentBody, onTap: onNo),
                _DialogButton(label: AppStrings.chatLeaveYes, color: AppColors.primary, onTap: onYes),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DialogButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.dialogHighlight,
        highlightColor: AppColors.dialogHighlight,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: AppSizes.paddingS,
          ),
          child: Text(
            label,
            style: AppTextStyles.poppins(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.30),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingM,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$message Repeated offenses will result in a ban.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              fontSize: AppSizes.fontSM,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSizes.paddingS),
          GestureDetector(
            onTap: () {
              final community =
                  context.read<CommunityProvider>().activeCommunity;
              if (community != null) {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierColor: Colors.black45,
                  builder: (_) => CommunityInfoModal(community: community),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Open the Info menu to view community rules.'),
                  ),
                );
              }
            },
            child: Text(
              'Review rules',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontSM,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ).copyWith(
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
