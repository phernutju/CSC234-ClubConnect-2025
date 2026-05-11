import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/event_bill_model.dart';
import '../../../providers/event_bill_provider.dart';
import '../../../providers/auth_provider.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const _kBg = Color(0xFFFFE8E0);
const _kPrimary = Color(0xFFFF6F4D);
const _kTextDark = Color(0xFF2B2B2B);
const _kMuted = Color(0xFF8A8A8A);
const _kSuccess = Color(0xFF2E9E5B);
const _kDanger = Color(0xFFE24B4A);
const _kEditHighlight = Color(0xFFFFF5F1);

// ── Internal working types ───────────────────────────────────────────────────
class _EditableItem {
  final String id;
  String name;
  double amount;
  _EditableItem({required this.id, required this.name, required this.amount});
}

class _EditableParticipant {
  final String id;
  final String userId;
  List<_EditableItem> items;

  _EditableParticipant({required this.id, required this.userId, required this.items});

  String get displayName {
    final m = RegExp(r'^([a-zA-Z]+)(\d+)$').firstMatch(userId);
    if (m != null) {
      final w = m.group(1)!;
      return '${w[0].toUpperCase()}${w.substring(1)} ${m.group(2)}';
    }
    return userId;
  }

  double get total => items.fold(0.0, (s, i) => s + i.amount);
}

String _uid() => UniqueKey().hashCode.toRadixString(16);

// ── Screen ────────────────────────────────────────────────────────────────────
class CreateBillScreen extends StatefulWidget {
  final String communityId;
  final String eventId;
  final String eventName;
  const CreateBillScreen({
    super.key,
    required this.communityId,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  final _titleController = TextEditingController();
  final _editNameCtrl = TextEditingController();
  final _editAmountCtrl = TextEditingController();
  final _editNameFocus = FocusNode();

  final List<_EditableParticipant> _participants = [];
  int _memberCounter = 0;
  bool _qrUploaded = false;

  // Item UX state
  String? _revealedItemId; // STATE B
  String? _editingItemId; // STATE C
  String? _editingParticipantId;

  bool get _isEditing => _editingItemId != null;

  double get _totalAmount => _participants.fold(0.0, (s, p) => s + p.total);
  int get _totalItems => _participants.fold(0, (s, p) => s + p.items.length);

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.eventName;
    // connected to BillProvider — subscribe to bill stream for this event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BillProvider>().loadBills(widget.communityId, widget.eventId);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _editNameCtrl.dispose();
    _editAmountCtrl.dispose();
    _editNameFocus.dispose();
    super.dispose();
  }

  // ── Member actions ────────────────────────────────────────────────────────
  void _showAddMemberDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add member',
            style: TextStyle(color: _kTextDark, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Display name',
            hintStyle: const TextStyle(color: _kMuted),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
          onSubmitted: (_) {
            Navigator.pop(ctx);
            _addMember(ctrl.text.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _kMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _addMember(ctrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary, foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addMember(String _) {
    _memberCounter++;
    final userId = 'user${_memberCounter.toString().padLeft(3, '0')}';
    setState(() {
      _participants.add(
          _EditableParticipant(id: _uid(), userId: userId, items: []));
    });
  }

  void _removeMember(String participantId) {
    setState(() {
      _participants.removeWhere((p) => p.id == participantId);
      if (_editingParticipantId == participantId) {
        _editingItemId = null;
        _editingParticipantId = null;
      }
      _revealedItemId = null;
    });
  }

  // ── Item reveal (STATE B) ─────────────────────────────────────────────────
  void _toggleReveal(String itemId) {
    if (_isEditing) return;
    setState(() {
      _revealedItemId = _revealedItemId == itemId ? null : itemId;
    });
  }

  void _closeReveal() {
    if (_revealedItemId != null) setState(() => _revealedItemId = null);
  }

  // ── Item edit (STATE C) ───────────────────────────────────────────────────
  void _startEdit(String participantId, String itemId) {
    final p = _participants.firstWhere((p) => p.id == participantId);
    final item = p.items.firstWhere((i) => i.id == itemId);
    setState(() {
      _editingParticipantId = participantId;
      _editingItemId = itemId;
      _revealedItemId = null;
      _editNameCtrl.text = item.name;
      _editAmountCtrl.text = item.amount == 0 ? '' : item.amount.toStringAsFixed(2);
    });
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _editNameFocus.requestFocus();
    });
  }

  void _saveEdit() {
    final name = _editNameCtrl.text.trim();
    final amount = double.tryParse(_editAmountCtrl.text) ?? 0.0;
    if (name.isEmpty) {
      _snack('Item name cannot be empty');
      return;
    }
    if (amount < 0) {
      _snack('Amount must be ≥ 0');
      return;
    }
    setState(() {
      final p = _participants.firstWhere((p) => p.id == _editingParticipantId);
      final item = p.items.firstWhere((i) => i.id == _editingItemId);
      item.name = name;
      item.amount = amount;
      _editingItemId = null;
      _editingParticipantId = null;
    });
  }

  void _cancelEdit() {
    final pid = _editingParticipantId;
    final iid = _editingItemId;
    setState(() {
      final p = _participants.firstWhere((p) => p.id == pid);
      final item = p.items.firstWhere((i) => i.id == iid);
      // Drop empty newly-added items on cancel
      if (item.name.isEmpty && item.amount == 0) p.items.remove(item);
      _editingItemId = null;
      _editingParticipantId = null;
    });
  }

  void _addItem(String participantId) {
    final newId = _uid();
    setState(() {
      final p = _participants.firstWhere((p) => p.id == participantId);
      p.items.add(_EditableItem(id: newId, name: '', amount: 0));
      _editingParticipantId = participantId;
      _editingItemId = newId;
      _revealedItemId = null;
      _editNameCtrl.text = '';
      _editAmountCtrl.text = '';
    });
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _editNameFocus.requestFocus();
    });
  }

  void _deleteItem(String participantId, String itemId) {
    setState(() {
      final p = _participants.firstWhere((p) => p.id == participantId);
      p.items.removeWhere((i) => i.id == itemId);
      if (_revealedItemId == itemId) _revealedItemId = null;
    });
  }

  // ── Publish ───────────────────────────────────────────────────────────────
  Future<void> _publish() async {
    if (_titleController.text.trim().isEmpty) {
      _snack('Please enter a bill title');
      return;
    }
    if (_participants.isEmpty) {
      _snack('Add at least one member');
      return;
    }
    if (_totalItems == 0) {
      _snack('Add at least one item');
      return;
    }
    if (_isEditing) {
      _snack('Finish editing the current item first');
      return;
    }

    // connected to BillProvider — build models from form fields
    final provider = context.read<BillProvider>();
    final uid = context.read<AppAuthProvider>().user?.uid ?? '';

    final bill = EventBillModel(
      id: '',
      title: _titleController.text.trim(),
      description: '',
      createdBy: uid,
      qrImageUrl: '',
      totalAmount: _totalAmount,
      status: BillStatus.pending,
      createdAt: DateTime.now(),
    );

    final participantModels = _participants
        .map((p) => BillParticipantModel(
              userId: p.userId,
              userName: p.displayName,
              userAvatar: '',
              items: p.items
                  .map((i) => BillItem(name: i.name, amount: i.amount))
                  .toList(),
            ))
        .toList();

    // connected to BillProvider — create bill document
    await provider.createBill(widget.communityId, widget.eventId, bill);
    if (!mounted) return;

    if (provider.error != null) {
      _snack(provider.error!);
      return;
    }

    // Add participants to the subcollection using the newly created bill's ID
    if (provider.bills.isNotEmpty && participantModels.isNotEmpty) {
      final newBillId = provider.bills.first.id;

      // connected to BillProvider — select bill so addParticipant host-check passes
      await provider.selectBill(widget.communityId, widget.eventId, newBillId);
      if (!mounted) return;

      if (provider.error == null) {
        for (final p in participantModels) {
          await provider.addParticipant(
              widget.communityId, widget.eventId, newBillId, p);
          if (!mounted) return;
          if (provider.error != null) break;
        }
      }
    }

    if (!mounted) return;
    if (provider.error != null) {
      _snack(provider.error!);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bill published to members!')),
    );
    context.pop();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // connected to BillProvider — watch loading state to drive button/spinner
    final isLoading = context.watch<BillProvider>().isLoading;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _closeReveal,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Create Bill', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 16),
              _buildTitleField(),
              const SizedBox(height: 20),
              _buildMembersSection(),
              const SizedBox(height: 20),
              _buildItemsSection(),
              const SizedBox(height: 20),
              _buildQrSection(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(isLoading),
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _SummaryCell(
            value: '฿${_totalAmount.toStringAsFixed(2)}',
            label: 'Total',
            valueColor: _kPrimary,
            bold: true,
          ),
          _vDivider(),
          _SummaryCell(value: '$_totalItems', label: 'Items'),
          _vDivider(),
          _SummaryCell(value: '${_participants.length}', label: 'Members'),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 40, color: const Color(0xFFEEEEEE));

  // ── Title field ───────────────────────────────────────────────────────────
  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      enabled: !_isEditing,
      decoration: InputDecoration(
        hintText: 'e.g. Dinner at Car Kee',
        hintStyle: const TextStyle(color: _kMuted),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
      ),
    );
  }

  // ── Members section ───────────────────────────────────────────────────────
  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Members',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kTextDark)),
        const SizedBox(height: 10),
        if (_participants.isEmpty)
          _HintCard(text: "No members yet — tap '+ Add member' below")
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _participants.map(_buildMemberChip).toList(),
          ),
        const SizedBox(height: 10),
        AnimatedOpacity(
          opacity: _isEditing ? 0.4 : 1.0,
          duration: const Duration(milliseconds: 220),
          child: IgnorePointer(
            ignoring: _isEditing,
            child: _DashedButton(
              label: '+ Add member',
              onTap: _showAddMemberDialog,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberChip(_EditableParticipant p) {
    return Chip(
      label: Text(p.displayName),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _kPrimary),
      ),
      deleteIcon: const Icon(Icons.close, size: 16, color: _kPrimary),
      onDeleted: _isEditing ? null : () => _removeMember(p.id),
      labelStyle: const TextStyle(color: _kTextDark, fontSize: 13),
    );
  }

  // ── Items section ─────────────────────────────────────────────────────────
  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bill items',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kTextDark)),
        const SizedBox(height: 10),
        if (_participants.isEmpty)
          const _HintCard(text: 'Add members first to assign items')
        else
          ...List.generate(_participants.length, (i) {
            final p = _participants[i];
            final isThisEdited = _editingParticipantId == p.id;
            final dimmed = _isEditing && !isThisEdited;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnimatedOpacity(
                opacity: dimmed ? 0.4 : 1.0,
                duration: const Duration(milliseconds: 220),
                child: IgnorePointer(
                  ignoring: dimmed,
                  child: _ParticipantEditCard(
                    participant: p,
                    revealedItemId: _revealedItemId,
                    editingItemId: _editingItemId,
                    editingParticipantId: _editingParticipantId,
                    editNameCtrl: _editNameCtrl,
                    editAmountCtrl: _editAmountCtrl,
                    editNameFocus: _editNameFocus,
                    isEditing: _isEditing,
                    onToggleReveal: _toggleReveal,
                    onStartEdit: _startEdit,
                    onDeleteItem: _deleteItem,
                    onAddItem: _addItem,
                    onSave: _saveEdit,
                    onCancel: _cancelEdit,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  // ── QR section ────────────────────────────────────────────────────────────
  Widget _buildQrSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PromptPay QR',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kTextDark)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            // TODO: replace with image_picker when integrating real QR upload
            setState(() => _qrUploaded = !_qrUploaded);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: _qrUploaded
                  ? const Color(0xFFF0FFF7)
                  : const Color(0xFFFFF5F1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _qrUploaded ? _kSuccess : _kPrimary,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _qrUploaded ? Icons.check_circle_rounded : Icons.upload_rounded,
                  color: _qrUploaded ? _kSuccess : _kPrimary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  _qrUploaded ? 'QR uploaded' : 'Upload your PromptPay QR',
                  style: TextStyle(
                    color: _qrUploaded ? _kSuccess : _kPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!_qrUploaded) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'JPG or PNG · members scan to pay',
                    style: TextStyle(color: _kMuted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar(bool isLoading) {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          // connected to BillProvider — disabled while submitting
          onPressed: isLoading ? null : _publish,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Publish bill to members',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}

// ── Participant card (host editing) ──────────────────────────────────────────
class _ParticipantEditCard extends StatelessWidget {
  final _EditableParticipant participant;
  final String? revealedItemId;
  final String? editingItemId;
  final String? editingParticipantId;
  final TextEditingController editNameCtrl;
  final TextEditingController editAmountCtrl;
  final FocusNode editNameFocus;
  final bool isEditing;

  final void Function(String itemId) onToggleReveal;
  final void Function(String participantId, String itemId) onStartEdit;
  final void Function(String participantId, String itemId) onDeleteItem;
  final void Function(String participantId) onAddItem;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _ParticipantEditCard({
    required this.participant,
    required this.revealedItemId,
    required this.editingItemId,
    required this.editingParticipantId,
    required this.editNameCtrl,
    required this.editAmountCtrl,
    required this.editNameFocus,
    required this.isEditing,
    required this.onToggleReveal,
    required this.onStartEdit,
    required this.onDeleteItem,
    required this.onAddItem,
    required this.onSave,
    required this.onCancel,
  });

  bool get _thisParticipantEditing => editingParticipantId == participant.id;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _kBg,
                  child: Text(
                    participant.displayName[0],
                    style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(participant.displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: _kTextDark)),
                      Text(participant.userId,
                          style: const TextStyle(fontSize: 12, color: _kMuted)),
                    ],
                  ),
                ),
                Text(
                  '฿${participant.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: _kPrimary, fontSize: 16),
                ),
              ],
            ),
          ),

          if (participant.items.isNotEmpty)
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Item rows
          ...participant.items.map((item) {
            final isEditingThis =
                editingItemId == item.id && editingParticipantId == participant.id;
            final otherDimmed = _thisParticipantEditing && !isEditingThis;

            if (isEditingThis) {
              return _EditCard(
                item: item,
                nameCtrl: editNameCtrl,
                amountCtrl: editAmountCtrl,
                nameFocus: editNameFocus,
                onSave: onSave,
                onCancel: onCancel,
              );
            }

            return AnimatedOpacity(
              key: ValueKey(item.id),
              opacity: otherDimmed ? 0.35 : 1.0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: otherDimmed,
                child: _ItemRow(
                  item: item,
                  isRevealed: revealedItemId == item.id,
                  onToggleReveal: () => onToggleReveal(item.id),
                  onEdit: () => onStartEdit(participant.id, item.id),
                  onDelete: () => onDeleteItem(participant.id, item.id),
                ),
              ),
            );
          }),

          // Add item button
          AnimatedOpacity(
            opacity: isEditing ? 0.35 : 1.0,
            duration: const Duration(milliseconds: 220),
            child: IgnorePointer(
              ignoring: isEditing,
              child: TextButton.icon(
                onPressed: () => onAddItem(participant.id),
                icon: const Icon(Icons.add, color: _kPrimary, size: 18),
                label: const Text('Add item', style: TextStyle(color: _kPrimary)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Item row (STATE A → B) ───────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final _EditableItem item;
  final bool isRevealed;
  final VoidCallback onToggleReveal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemRow({
    required this.item,
    required this.isRevealed,
    required this.onToggleReveal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onToggleReveal,
      onTap: isRevealed ? onToggleReveal : null,
      child: ClipRect(
        child: Stack(
          children: [
            // Revealed action buttons (right-aligned, beneath slide)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionBtn(
                    color: _kPrimary,
                    icon: Icons.edit_rounded,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    color: _kDanger,
                    icon: Icons.delete_rounded,
                    onTap: onDelete,
                  ),
                ],
              ),
            ),
            // Sliding row content
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              transform: Matrix4.translationValues(isRevealed ? -104 : 0, 0, 0),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(item.name, style: const TextStyle(color: _kTextDark)),
                    ),
                    Text(
                      '฿${item.amount.toStringAsFixed(2)}',
                      style: const TextStyle(color: _kTextDark),
                      textAlign: TextAlign.right,
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

class _ActionBtn extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 36,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ── Edit card (STATE C) ───────────────────────────────────────────────────────
class _EditCard extends StatelessWidget {
  final _EditableItem item;
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  final FocusNode nameFocus;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditCard({
    required this.item,
    required this.nameCtrl,
    required this.amountCtrl,
    required this.nameFocus,
    required this.onSave,
    required this.onCancel,
  });

  bool get _isNew => item.name.isEmpty && item.amount == 0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.97, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: _kEditHighlight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                border: Border(bottom: BorderSide(color: Color(0xFFEEE0D8))),
              ),
              child: Row(
                children: [
                  _BadgePill(isNew: _isNew),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isNew ? 'Add item details' : item.name,
                      style: TextStyle(
                        color: _isNew ? _kMuted : _kTextDark,
                        fontSize: 13,
                      ),
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
                  const _FieldLabel('ITEM NAME'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    focusNode: nameFocus,
                    decoration: _fieldDecoration('e.g. Pad Thai'),
                    onSubmitted: (_) => onSave(),
                  ),
                  const SizedBox(height: 12),
                  const _FieldLabel('PRICE'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
                    decoration: _fieldDecoration('0.00', prefix: '฿  '),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                    onSubmitted: (_) => onSave(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kTextDark,
                            side: const BorderSide(color: Color(0xFFCCCCCC)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onSave,
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
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

  InputDecoration _fieldDecoration(String hint, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _kMuted),
      prefixText: prefix,
      prefixStyle: const TextStyle(color: _kTextDark),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final bool isNew;
  const _BadgePill({required this.isNew});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isNew ? Icons.add_rounded : Icons.edit_rounded, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            isNew ? 'New' : 'Editing',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 10, color: _kMuted, letterSpacing: 0.8, fontWeight: FontWeight.w600),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────
class _SummaryCell extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final bool bold;

  const _SummaryCell({
    required this.value,
    required this.label,
    this.valueColor = _kTextDark,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: _kMuted)),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final String text;
  const _HintCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Text(text, style: const TextStyle(color: _kMuted), textAlign: TextAlign.center),
    );
  }
}

class _DashedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _DashedButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashPainter(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kPrimary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashW = 6.0;
    const dashGap = 4.0;
    const r = 12.0;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(r)));
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, min(d + dashW, m.length)), paint);
        d += dashW + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
