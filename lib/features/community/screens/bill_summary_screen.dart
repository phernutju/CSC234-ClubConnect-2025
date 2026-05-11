import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_constants.dart';
import '../../../data/mock_data.dart';
import '../../../models/bill_data.dart';
import '../../../models/bill_payment_args.dart';

// ── Local design tokens not in AppColors ─────────────────────────────────────
const _kCardBorder = Color(0xFFEDE5DF);
const _kSuccess    = Color(0xFF2E9E5B);
const _kDanger     = Color(0xFFE24B4A);

const _kAvatarColors = [
  Color(0xFFFFB347), Color(0xFF77DD77), Color(0xFF89CFF0), Color(0xFFCDA4DE),
  Color(0xFFFF9F80), Color(0xFFAEC6CF), Color(0xFFFFD1DC), Color(0xFFB5EAD7),
];

// ── Internal editable type ────────────────────────────────────────────────────

class _EditableItem {
  final String id;
  String name;
  double amount;
  _EditableItem({required this.id, required this.name, required this.amount});
}

String _uid() => UniqueKey().hashCode.toRadixString(16);

// ── Screen ────────────────────────────────────────────────────────────────────

class BillSummaryScreen extends StatefulWidget {
  final BillData billData;
  final bool     isCurrentUserHost;
  const BillSummaryScreen({
    super.key,
    required this.billData,
    this.isCurrentUserHost = false,
  });

  @override
  State<BillSummaryScreen> createState() => _BillSummaryScreenState();
}

class _BillSummaryScreenState extends State<BillSummaryScreen> {
  String _currentUserStatus = 'unpaid';
  bool   _showPaidBanner    = false;

  // Populated from mockBill in initState
  String?                    _localTitle;
  List<BillMemberData>?      _localMembers;
  List<List<_EditableItem>>? _memberItems;

  // Mutable item list (host can edit / delete); flattened from _memberItems
  List<_EditableItem> _items = [];
  String? _revealedItemId;
  String? _editingItemId;

  final _editNameCtrl   = TextEditingController();
  final _editAmountCtrl = TextEditingController();
  final _editNameFocus  = FocusNode();

  bool get _isEditing => _editingItemId != null;

  @override
  void initState() {
    super.initState();
    _localTitle = mockBill.title;

    final builtMembers     = <BillMemberData>[];
    final builtMemberItems = <List<_EditableItem>>[];

    for (final p in mockBill.participants) {
      // "user001" → "User 001"
      final m = RegExp(r'^([a-zA-Z]+)(\d+)$').firstMatch(p.userId);
      final displayName = m != null
          ? '${m.group(1)![0].toUpperCase()}${m.group(1)!.substring(1)} ${m.group(2)}'
          : p.userId;
      final parts    = displayName.split(' ');
      final initials = parts
          .take(2)
          .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
          .join();

      builtMembers.add(BillMemberData(
        name:     displayName,
        initials: initials,
        role:     '',
        isHost:   false,
        status:   p.isPaid ? 'paid' : 'unpaid',
      ));

      builtMemberItems.add(
        p.items
            .map((i) => _EditableItem(id: _uid(), name: i.name, amount: i.amount))
            .toList(),
      );
    }

    _localMembers = builtMembers;
    _memberItems  = builtMemberItems;
    // Flatten for global tracking (summary total, host-edit lookup)
    _items = builtMemberItems.expand((list) => list).toList();
  }

  @override
  void dispose() {
    _editNameCtrl.dispose();
    _editAmountCtrl.dispose();
    _editNameFocus.dispose();
    super.dispose();
  }

  List<BillMemberData> get _members =>
      _localMembers ?? widget.billData.members;

  double get _total     => _items.fold(0.0, (s, i) => s + i.amount);
  int    get _nMembers  => _members.isNotEmpty ? _members.length : 1;
  double get _perPerson =>
      _nMembers > 0 ? (_total / _nMembers).floorToDouble() : 0.0;
  int    get _paidCount =>
      _members.where((m) => m.status == 'paid').length;

  // Amount owed by the current user (last member = current user in demo)
  double get _currentUserAmount {
    if (_memberItems != null && _memberItems!.isNotEmpty) {
      final idx = _memberItems!.length - 1;
      return _memberItems![idx].fold(0.0, (s, i) => s + i.amount);
    }
    return _perPerson;
  }

  String get _statusLabel {
    if (_paidCount == _members.length && _members.isNotEmpty) { return 'Done'; }
    if (_paidCount > 0) { return 'Partial'; }
    return 'Pending';
  }

  Color get _statusColor {
    switch (_statusLabel) {
      case 'Done':    return _kSuccess;
      case 'Partial': return AppColors.primary;
      default:        return AppColors.textDark;
    }
  }

  // ── Item reveal (STATE B) ─────────────────────────────────────────────────

  void _toggleReveal(String itemId) {
    if (_isEditing) return;
    setState(() => _revealedItemId = _revealedItemId == itemId ? null : itemId);
  }

  void _closeReveal() {
    if (_revealedItemId != null) setState(() => _revealedItemId = null);
  }

  // ── Item edit (STATE C) ───────────────────────────────────────────────────

  void _startEdit(String itemId) {
    final item = _items.firstWhere((i) => i.id == itemId);
    setState(() {
      _editingItemId       = itemId;
      _revealedItemId      = null;
      _editNameCtrl.text   = item.name;
      _editAmountCtrl.text =
          item.amount == 0 ? '' : item.amount.toStringAsFixed(2);
    });
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _editNameFocus.requestFocus();
    });
  }

  void _saveEdit() {
    final name   = _editNameCtrl.text.trim();
    final amount = double.tryParse(_editAmountCtrl.text) ?? 0.0;
    if (name.isEmpty) { _snack('Item name cannot be empty'); return; }
    if (amount < 0)   { _snack('Amount must be ≥ 0');       return; }
    setState(() {
      final item  = _items.firstWhere((i) => i.id == _editingItemId);
      item.name   = name;
      item.amount = amount;
      _editingItemId = null;
    });
  }

  void _cancelEdit() => setState(() => _editingItemId = null);

  void _deleteItem(String itemId) {
    setState(() {
      _items.removeWhere((i) => i.id == itemId);
      for (final memberList in (_memberItems ?? [])) {
        memberList.removeWhere((i) => i.id == itemId);
      }
      if (_revealedItemId == itemId) _revealedItemId = null;
    });
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _goToPay(BuildContext context) async {
    final result = await context.push<bool>(
      '/bill-payment',
      extra: BillPaymentArgs(
        eventName:   _localTitle ?? widget.billData.eventName,
        amount:      _currentUserAmount,
        memberCount: _nMembers,
        memberIndex: 4,
      ),
    );
    if (result == true && mounted) {
      setState(() {
        _currentUserStatus = 'pending';
        _showPaidBanner    = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    if (_items.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const _BillAppBar(title: 'Bill Summary'),
            const Expanded(child: _EmptyBillState()),
          ],
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap:    _closeReveal,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Column(
              children: [
                _BillAppBar(title: _localTitle ?? widget.billData.eventName),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_showPaidBanner) ...[
                          const _PaidBanner(),
                          const SizedBox(height: 8),
                        ],

                        _SummaryCard(
                          total:        _total,
                          paidCount:    _paidCount,
                          totalMembers: _nMembers,
                          statusLabel:  _statusLabel,
                          statusColor:  _statusColor,
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'Who pays what',
                          style: GoogleFonts.poppins(
                            fontSize:   AppSizes.fontSM,
                            fontWeight: FontWeight.w600,
                            color:      AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),

                        ..._members.asMap().entries.map((e) {
                          final idx    = e.key;
                          final member = e.value;
                          final effectiveStatus =
                              (idx == _members.length - 1 &&
                                      _currentUserStatus != 'unpaid')
                                  ? _currentUserStatus
                                  : member.status;

                          // Per-participant items and total (nMembers=1 → no division)
                          final cardItems   = _memberItems?[idx] ?? _items;
                          final cardAmount  = _memberItems != null
                              ? _memberItems![idx].fold(0.0, (s, i) => s + i.amount)
                              : _perPerson;
                          final cardNMembers = _memberItems != null ? 1 : _nMembers;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MemberCard(
                              member:          member,
                              effectiveStatus: effectiveStatus,
                              perPerson:       cardAmount,
                              items:           cardItems,
                              nMembers:        cardNMembers,
                              colorIndex:      idx,
                              isHost:          widget.isCurrentUserHost,
                              revealedItemId:  _revealedItemId,
                              editingItemId:   _editingItemId,
                              editNameCtrl:    _editNameCtrl,
                              editAmountCtrl:  _editAmountCtrl,
                              editNameFocus:   _editNameFocus,
                              onToggleReveal:  _toggleReveal,
                              onStartEdit:     _startEdit,
                              onSave:          _saveEdit,
                              onCancel:        _cancelEdit,
                              onDelete:        _deleteItem,
                            ),
                          );
                        }),

                        SizedBox(height: 100 + bottomPad),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _StickyFooter(
                label: _currentUserStatus == 'pending'
                    ? 'Payment submitted — awaiting confirmation'
                    : 'Pay my share  ฿${_currentUserAmount.toInt()}',
                bgColor:   AppColors.background,
                bottomPad: bottomPad,
                isPending: _currentUserStatus == 'pending',
                onTap:     () => _goToPay(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyBillState extends StatelessWidget {
  const _EmptyBillState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 64, color: AppColors.textGray),
            const SizedBox(height: 16),
            Text(
              'No bill yet',
              style: GoogleFonts.poppins(
                fontSize:   AppSizes.fontL,
                fontWeight: FontWeight.w500,
                color:      AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "The host hasn't created a bill yet.\nCheck back later!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: AppSizes.fontXS,
                color:    AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _BillAppBar extends StatelessWidget {
  final String title;
  const _BillAppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   AppColors.primary,
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
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize:   AppSizes.fontL,
                  fontWeight: FontWeight.w600,
                  color:      AppColors.cardWhite,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary card (Total | Paid X/Y | Status) ──────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double total;
  final int    paidCount;
  final int    totalMembers;
  final String statusLabel;
  final Color  statusColor;

  const _SummaryCard({
    required this.total,
    required this.paidCount,
    required this.totalMembers,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border:       Border.all(color: _kCardBorder, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          _StatCell(
            label:      'Total',
            value:      '฿${total.toStringAsFixed(2)}',
            valueColor: AppColors.primary,
            bold:       true,
          ),
          _VDivider(),
          _StatCell(label: 'Paid', value: '$paidCount/$totalMembers'),
          _VDivider(),
          _StatCell(
              label: 'Status', value: statusLabel, valueColor: statusColor),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color  valueColor;
  final bool   bold;
  const _StatCell({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textDark,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize:   AppSizes.fontXL,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color:      valueColor,
            ),
            textAlign: TextAlign.center,
          ),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: AppSizes.fontXXS, color: AppColors.textGray)),
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, height: 44, color: _kCardBorder);
}

// ── Member participant card ───────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final BillMemberData        member;
  final String                effectiveStatus;
  final double                perPerson;
  final List<_EditableItem>   items;
  final int                   nMembers;
  final int                   colorIndex;
  final bool                  isHost;
  final String?               revealedItemId;
  final String?               editingItemId;
  final TextEditingController editNameCtrl;
  final TextEditingController editAmountCtrl;
  final FocusNode             editNameFocus;
  final void Function(String) onToggleReveal;
  final void Function(String) onStartEdit;
  final void Function(String) onDelete;
  final VoidCallback          onSave;
  final VoidCallback          onCancel;

  const _MemberCard({
    required this.member,
    required this.effectiveStatus,
    required this.perPerson,
    required this.items,
    required this.nMembers,
    required this.colorIndex,
    required this.isHost,
    required this.revealedItemId,
    required this.editingItemId,
    required this.editNameCtrl,
    required this.editAmountCtrl,
    required this.editNameFocus,
    required this.onToggleReveal,
    required this.onStartEdit,
    required this.onDelete,
    required this.onSave,
    required this.onCancel,
  });

  bool get _isPaid    => effectiveStatus == 'paid';
  bool get _isEditing => editingItemId != null;

  @override
  Widget build(BuildContext context) {
    final avatarColor = _kAvatarColors[colorIndex % _kAvatarColors.length];
    final initial     = member.initials.isNotEmpty ? member.initials[0] : '?';

    return Container(
      decoration: BoxDecoration(
        color:        AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(
          color: _isPaid
              ? _kSuccess.withValues(alpha: 0.5)
              : _kCardBorder,
          width: _isPaid ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        children: [
          // Header row — unchanged
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width:  40,
                  height: 40,
                  decoration:
                      BoxDecoration(color: avatarColor, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: GoogleFonts.poppins(
                        fontSize:   AppSizes.fontSM,
                        fontWeight: FontWeight.w700,
                        color:      AppColors.cardWhite),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.name,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color:      AppColors.textDark,
                                  fontSize:   AppSizes.fontSM),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (member.isHost) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Host',
                                style: GoogleFonts.poppins(
                                    fontSize:   AppSizes.fontXXXS,
                                    fontWeight: FontWeight.w600,
                                    color:      AppColors.primary),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      _StatusPill(status: effectiveStatus),
                    ],
                  ),
                ),
                Text(
                  '฿${perPerson.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color:      AppColors.primary,
                      fontSize:   AppSizes.fontML),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.5, color: _kCardBorder),

          // Item breakdown
          // Host: full-width rows for slide-reveal / edit card
          // Member: read-only padded rows (unchanged appearance)
          if (!isHost)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                children: items.map((item) {
                  final share =
                      nMembers > 0 ? item.amount / nMembers : item.amount;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Text('•  ',
                            style: GoogleFonts.poppins(
                                fontSize: AppSizes.fontXS,
                                color:    AppColors.textGray)),
                        Expanded(
                          child: Text(item.name,
                              style: GoogleFonts.poppins(
                                  fontSize: AppSizes.fontXS,
                                  color:    AppColors.textDark)),
                        ),
                        Text(
                          '฿${share.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                              fontSize: AppSizes.fontXS,
                              color:    AppColors.textDark),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: items.map((item) {
                  // STATE C — edit card
                  if (editingItemId == item.id) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: _ItemEditCard(
                        item:      item,
                        nameCtrl:  editNameCtrl,
                        amtCtrl:   editAmountCtrl,
                        nameFocus: editNameFocus,
                        onSave:    onSave,
                        onCancel:  onCancel,
                      ),
                    );
                  }

                  final share =
                      nMembers > 0 ? item.amount / nMembers : item.amount;
                  final dimmed = _isEditing;

                  return AnimatedOpacity(
                    key:      ValueKey(item.id),
                    opacity:  dimmed ? 0.35 : 1.0,
                    duration: const Duration(milliseconds: 220),
                    child: IgnorePointer(
                      ignoring: dimmed,
                      // STATE A / B — slide-reveal row
                      child: _ItemSummaryRow(
                        item:           item,
                        share:          share,
                        isRevealed:     revealedItemId == item.id,
                        onToggleReveal: () => onToggleReveal(item.id),
                        onEdit:         () => onStartEdit(item.id),
                        onDelete:       () => onDelete(item.id),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Status pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == 'paid') {
      return _pill(
          label: 'Paid',
          bg:    _kSuccess.withValues(alpha: 0.12),
          fg:    _kSuccess);
    }
    if (status == 'pending') {
      return _pill(
          label: 'Pending',
          bg:    const Color(0xFFFFF8E6),
          fg:    const Color(0xFFD97706));
    }
    return _pill(
        label: 'Unpaid',
        bg:    AppColors.primary.withValues(alpha: 0.10),
        fg:    AppColors.primary);
  }

  Widget _pill({required String label, required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.poppins(
              color:      fg,
              fontSize:   AppSizes.fontXXS,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ── Paid banner ───────────────────────────────────────────────────────────────

class _PaidBanner extends StatelessWidget {
  const _PaidBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        const Color(0xFFE8F9F0),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border:       Border.all(color: const Color(0xFF86EFAC), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFF15803D), size: 18),
          const SizedBox(width: 8),
          Text(
            "You've paid! 🎉",
            style: GoogleFonts.poppins(
              fontSize:   AppSizes.fontXS,
              fontWeight: FontWeight.w600,
              color:      const Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sticky footer ─────────────────────────────────────────────────────────────

class _StickyFooter extends StatelessWidget {
  final String       label;
  final Color        bgColor;
  final double       bottomPad;
  final VoidCallback onTap;
  final bool         isPending;

  const _StickyFooter({
    required this.label,
    required this.bgColor,
    required this.bottomPad,
    required this.onTap,
    this.isPending = false,
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
              end:   Alignment.bottomCenter,
              colors: [bgColor.withValues(alpha: 0), bgColor],
            ),
          ),
        ),
        Container(
          color:   bgColor,
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, bottomPad > 0 ? bottomPad : 24),
          child: SizedBox(
            width:  double.infinity,
            height: AppSizes.buttonHeight,
            child: ElevatedButton(
              onPressed: isPending ? () {} : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPending ? const Color(0xFF15803D) : AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusPill)),
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize:   AppSizes.fontML,
                  fontWeight: FontWeight.w600,
                  color:      AppColors.cardWhite,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Item summary row — STATE A (normal) / STATE B (slide-revealed) ────────────

class _ItemSummaryRow extends StatelessWidget {
  final _EditableItem item;
  final double        share;
  final bool          isRevealed;
  final VoidCallback  onToggleReveal;
  final VoidCallback  onEdit;
  final VoidCallback  onDelete;

  const _ItemSummaryRow({
    required this.item,
    required this.share,
    required this.isRevealed,
    required this.onToggleReveal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior:    HitTestBehavior.opaque,
      onLongPress: onToggleReveal,
      onTap:       isRevealed ? onToggleReveal : null,
      child: ClipRect(
        child: Stack(
          children: [
            // Action buttons revealed on the right
            Positioned(
              right: 6, top: 0, bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SummaryActionBtn(
                      color: AppColors.primary,
                      icon:  Icons.edit_rounded,
                      onTap: onEdit),
                  const SizedBox(width: 6),
                  _SummaryActionBtn(
                      color: _kDanger,
                      icon:  Icons.delete_rounded,
                      onTap: onDelete),
                ],
              ),
            ),
            // Row content — slides left 96 px on reveal
            AnimatedContainer(
              duration:  const Duration(milliseconds: 220),
              curve:     Curves.easeInOut,
              transform:
                  Matrix4.translationValues(isRevealed ? -96 : 0, 0, 0),
              color: AppColors.cardWhite,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                child: Row(
                  children: [
                    Text('•  ',
                        style: GoogleFonts.poppins(
                            fontSize: AppSizes.fontXS,
                            color:    AppColors.textGray)),
                    Expanded(
                      child: Text(item.name,
                          style: GoogleFonts.poppins(
                              fontSize: AppSizes.fontXS,
                              color:    AppColors.textDark)),
                    ),
                    Text(
                      '฿${share.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                          fontSize: AppSizes.fontXS,
                          color:    AppColors.textDark),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryActionBtn extends StatelessWidget {
  final Color        color;
  final IconData     icon;
  final VoidCallback onTap;
  const _SummaryActionBtn(
      {required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  38,
        height: 30,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, color: Colors.white, size: 15),
      ),
    );
  }
}

// ── Inline edit card — STATE C ────────────────────────────────────────────────

class _ItemEditCard extends StatelessWidget {
  final _EditableItem         item;
  final TextEditingController nameCtrl;
  final TextEditingController amtCtrl;
  final FocusNode             nameFocus;
  final VoidCallback          onSave;
  final VoidCallback          onCancel;

  const _ItemEditCard({
    required this.item,
    required this.nameCtrl,
    required this.amtCtrl,
    required this.nameFocus,
    required this.onSave,
    required this.onCancel,
  });

  InputDecoration _fieldDecor(String hint, {String? prefix}) {
    return InputDecoration(
      hintText:    hint,
      hintStyle:   GoogleFonts.poppins(
          fontSize: AppSizes.fontSM, color: AppColors.textGray),
      prefixText:  prefix,
      prefixStyle: GoogleFonts.poppins(
          fontSize: AppSizes.fontSM, color: AppColors.textDark),
      filled:      true,
      fillColor:   AppColors.cardWhite,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween:    Tween(begin: 0.97, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve:    Curves.easeOut,
      builder:  (_, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color:        const Color(0xFFFFF5F1),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: AppColors.primary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color:      AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 8,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFEEE0D8))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color:        AppColors.primary,
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_rounded,
                            color: AppColors.cardWhite, size: 12),
                        const SizedBox(width: 4),
                        Text('Editing',
                            style: GoogleFonts.poppins(
                                fontSize:   AppSizes.fontXXS,
                                fontWeight: FontWeight.w600,
                                color:      AppColors.cardWhite)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.poppins(
                          fontSize: AppSizes.fontXS,
                          color:    AppColors.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Form body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ITEM NAME',
                      style: GoogleFonts.poppins(
                          fontSize:      AppSizes.fontXXS,
                          color:         AppColors.textGray,
                          letterSpacing: 0.8,
                          fontWeight:    FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    focusNode:  nameFocus,
                    style: GoogleFonts.poppins(
                        fontSize: AppSizes.fontSM,
                        color:    AppColors.textDark),
                    decoration: _fieldDecor('e.g. Pad Thai'),
                    onSubmitted: (_) => onSave(),
                  ),
                  const SizedBox(height: 12),
                  Text('PRICE',
                      style: GoogleFonts.poppins(
                          fontSize:      AppSizes.fontXXS,
                          color:         AppColors.textGray,
                          letterSpacing: 0.8,
                          fontWeight:    FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller:   amtCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                        fontSize: AppSizes.fontSM,
                        color:    AppColors.textDark),
                    decoration: _fieldDecor('0.00', prefix: '฿  '),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                    ],
                    onSubmitted: (_) => onSave(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textDark,
                            side: const BorderSide(
                                color: Color(0xFFCCCCCC)),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8)),
                          ),
                          child: Text('Cancel',
                              style: GoogleFonts.poppins(
                                  fontSize:   AppSizes.fontSM,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onSave,
                          icon:  const Icon(Icons.check_rounded, size: 16),
                          label: Text('Save',
                              style: GoogleFonts.poppins(
                                  fontSize:   AppSizes.fontSM,
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.cardWhite,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
