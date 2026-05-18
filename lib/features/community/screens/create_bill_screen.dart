import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../models/smart_bill_model.dart';
import '../../../providers/smart_bill_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/attendee_provider.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kPrimary  = Color(0xFFFF6B4A);
const _kBg       = Color(0xFFFDF5F0);
const _kCream    = Color(0xFFFAECE7);
const _kBorder   = Color(0xFFF0C4B0);
const _kDark     = Color(0xFF4A1B0C);
const _kMuted    = Color(0xFF9A7A6A);
const _kSuccess  = Color(0xFF2E9E5B);
const _kDanger   = Color(0xFFE24B4A);

const _kAvatarColors = [
  Color(0xFFFFB347), Color(0xFF77DD77), Color(0xFF89CFF0),
  Color(0xFFCDA4DE), Color(0xFFFF9F80), Color(0xFFAEC6CF),
  Color(0xFFFFD1DC), Color(0xFFB5EAD7),
];

String _genId() => UniqueKey().hashCode.toRadixString(16);

// ── Local editable item ───────────────────────────────────────────────────────
class _LocalItem {
  final String id;
  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  List<String> payerIds;

  _LocalItem({required this.id})
      : nameCtrl = TextEditingController(),
        priceCtrl = TextEditingController(),
        payerIds = [];

  _LocalItem.fromModel(SmartBillItemModel model)
      : id = model.id.isNotEmpty ? model.id : _genId(),
        nameCtrl = TextEditingController(text: model.name),
        priceCtrl = TextEditingController(
            text: model.price > 0 ? model.price.toStringAsFixed(2) : ''),
        payerIds = List<String>.from(model.payerIds);

  double get price => double.tryParse(priceCtrl.text) ?? 0;
  double get pricePerPayer =>
      payerIds.isEmpty ? 0 : price / payerIds.length;

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────
class CreateBillScreen extends StatefulWidget {
  final String communityId;
  final String eventId;
  final String eventName;
  final SmartBillModel? existingBill;
  final List<SmartBillItemModel>? existingItems;
  final bool isEdit;

  const CreateBillScreen({
    super.key,
    required this.communityId,
    required this.eventId,
    required this.eventName,
    this.existingBill,
    this.existingItems,
    this.isEdit = false,
  });

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  final _nameCtrl = TextEditingController();
  final List<_LocalItem> _items = [];
  final List<SmartBillMember> _members = [];
  int _memberCounter = 0;

  XFile? _qrFile;
  Uint8List? _qrBytes;
  String _existingQrUrl = '';

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.existingBill != null) {
      final bill = widget.existingBill!;
      _nameCtrl.text = bill.name;
      _existingQrUrl = bill.hostPromptPayQrUrl;
      for (final m in bill.members) {
        _members.add(m);
      }
      _memberCounter = _members.length;
      for (final item in widget.existingItems ?? []) {
        _items.add(_LocalItem.fromModel(item));
      }
    } else {
      _nameCtrl.text = widget.eventName;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final attendees = context.read<AttendeeProvider>().attendees;
        if (attendees.isEmpty) return;
        setState(() {
          for (final a in attendees) {
            _members.add(SmartBillMember(
              uid: a.userId,
              name: a.displayName,
              avatarUrl: a.avatarUrl ?? '',
            ));
          }
          _memberCounter = _members.length;
        });
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  double get _total => _items.fold(0.0, (s, i) => s + i.price);

  // ── Members ───────────────────────────────────────────────────────────────
  void _showAddMemberDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Member',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: _kDark)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Member name',
            hintStyle: GoogleFonts.poppins(color: _kMuted, fontSize: 14),
            filled: true,
            fillColor: _kCream,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          style: GoogleFonts.poppins(color: _kDark, fontSize: 14),
          onSubmitted: (_) {
            Navigator.pop(ctx);
            _addMember(ctrl.text.trim());
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: _kMuted))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _addMember(ctrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: Text('Add', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _addMember(String name) {
    if (name.isEmpty) return;
    _memberCounter++;
    setState(() {
      _members.add(SmartBillMember(
        uid: 'user${_memberCounter.toString().padLeft(3, '0')}',
        name: name,
      ));
    });
  }

  void _removeMember(String uid) {
    if (_members.length <= 1) return;
    setState(() {
      _members.removeWhere((m) => m.uid == uid);
      for (final item in _items) {
        item.payerIds.remove(uid);
      }
    });
  }

  // ── Items ─────────────────────────────────────────────────────────────────
  void _addItem() {
    setState(() => _items.add(_LocalItem(id: _genId())));
  }

  void _removeItem(String id) {
    final item = _items.firstWhere((i) => i.id == id);
    item.dispose();
    setState(() => _items.removeWhere((i) => i.id == id));
  }

  // ── Payer sheet ───────────────────────────────────────────────────────────
  Future<void> _showPayerSheet(_LocalItem item) async {
    if (_members.isEmpty) {
      _snack('Add a member first');
      return;
    }
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PayerSheet(
        itemName: item.nameCtrl.text.isNotEmpty
            ? item.nameCtrl.text
            : 'this item',
        members: _members,
        selected: List<String>.from(item.payerIds),
      ),
    );
    if (selected != null) {
      setState(() => item.payerIds = selected);
    }
  }

  // ── QR upload ─────────────────────────────────────────────────────────────
  Future<void> _pickQr() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _qrFile = picked;
        _qrBytes = bytes;
      });
    }
  }

  // ── Publish / Update ──────────────────────────────────────────────────────
  Future<void> _publish() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Please enter a bill name');
      return;
    }
    if (_members.isEmpty) {
      _snack('Please add at least 1 member');
      return;
    }
    if (_items.isEmpty) {
      _snack('Please add at least 1 item');
      return;
    }
    if (_items.any((i) => i.nameCtrl.text.trim().isEmpty || i.price <= 0)) {
      _snack('Please fill in name and price for all items');
      return;
    }

    final provider = context.read<SmartBillProvider>();
    final uid = context.read<AppAuthProvider>().user?.uid ?? '';

    final billItems = _items
        .map((i) => SmartBillItemModel(
              id: '',
              name: i.nameCtrl.text.trim(),
              price: i.price,
              payerIds: List<String>.from(i.payerIds),
            ))
        .toList();

    if (widget.isEdit && widget.existingBill != null) {
      await provider.updateAndPublishBill(
        communityId: widget.communityId,
        eventId: widget.eventId,
        existingBill: widget.existingBill!,
        name: _nameCtrl.text.trim(),
        members: _members,
        billItems: billItems,
        qrImageBytes: _qrBytes,
      );
      if (!mounted) return;
      if (provider.error != null) {
        _snack(provider.error!);
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bill updated!')));
      context.pop();
    } else {
      final created = await provider.createAndPublishBill(
        communityId: widget.communityId,
        eventId: widget.eventId,
        hostId: uid,
        name: _nameCtrl.text.trim(),
        members: _members,
        billItems: billItems,
        qrImageBytes: _qrBytes,
      );
      if (!mounted) return;
      if (provider.error != null) {
        _snack(provider.error!);
        return;
      }
      if (created != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Bill published!')));
        context.pop();
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<SmartBillProvider>().isLoading;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _BillAppBar(
            title: widget.isEdit ? 'Edit Bill' : 'Create Bill',
            trailing: IconButton(
              icon: const Icon(Icons.person_add_alt_1,
                  color: Colors.white, size: 22),
              tooltip: 'Add member',
              onPressed: _showAddMemberDialog,
            ),
          ),
          _buildStatsBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameField(),
                  const SizedBox(height: 20),
                  _buildItemsSection(),
                  const SizedBox(height: 20),
                  _buildQrSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isLoading, bottomPad),
    );
  }

  // ── Stats bar ─────────────────────────────────────────────────────────────
  Widget _buildStatsBar() {
    return Container(
      color: _kCream,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      child: Row(
        children: [
          _StatCell(
            label: 'Total ฿',
            value: _total.toStringAsFixed(2),
            bold: true,
            valueColor: _kPrimary,
          ),
          Container(width: 1, height: 34, color: _kBorder),
          _StatCell(label: 'Items', value: '${_items.length}'),
          Container(width: 1, height: 34, color: _kBorder),
          _StatCell(label: 'Members', value: '${_members.length}'),
        ],
      ),
    );
  }

  // ── Name field ────────────────────────────────────────────────────────────
  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('BILL NAME'),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          decoration: _fieldDecor('e.g. Dinner at Car Kee'),
          style: GoogleFonts.poppins(color: _kDark, fontSize: 14),
        ),
        if (_members.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _members.asMap().entries.map((e) {
              final idx = e.key;
              final m = e.value;
              return Chip(
                avatar: CircleAvatar(
                  radius: 10,
                  backgroundColor:
                      _kAvatarColors[idx % _kAvatarColors.length],
                  child: Text(
                    m.initials.substring(0, 1),
                    style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                label: Text(m.name,
                    style:
                        GoogleFonts.poppins(fontSize: 12, color: _kDark)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: _kBorder)),
                deleteIcon:
                    const Icon(Icons.close, size: 14, color: _kPrimary),
                onDeleted: () => _removeMember(m.uid),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ── Items section ─────────────────────────────────────────────────────────
  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionLabel('BILL ITEMS'),
            const Spacer(),
            GestureDetector(
              onTap: _addItem,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('Add item',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_items.isEmpty)
          _EmptyCard(
              text:
                  'No items yet\nTap "Add item" to get started'),
        ..._items.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildItemCard(e.value, e.key),
            )),
      ],
    );
  }

  Widget _buildItemCard(_LocalItem item, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: item.nameCtrl,
                    decoration:
                        _fieldDecor('Item name', fillColor: _kCream),
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: _kDark),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: item.priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[\d.]'))
                    ],
                    textAlign: TextAlign.right,
                    decoration:
                        _fieldDecor('0.00', fillColor: _kCream, prefix: '฿ '),
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: _kDark),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _removeItem(item.id),
                  child: Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFEEEE),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.delete_outline,
                        size: 16, color: _kDanger),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _kBorder),
          // Payer row
          GestureDetector(
            onTap: () => _showPayerSheet(item),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Avatar chips
                  if (item.payerIds.isEmpty)
                    Text('Select payers',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: _kMuted))
                  else ...[
                    ...item.payerIds.take(4).map((uid) {
                      final idx =
                          _members.indexWhere((m) => m.uid == uid);
                      final member =
                          idx >= 0 ? _members[idx] : null;
                      return Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          color: idx >= 0
                              ? _kAvatarColors[
                                  idx % _kAvatarColors.length]
                              : _kBorder,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          member?.initials.substring(0, 1) ?? '?',
                          style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      );
                    }),
                    if (item.payerIds.length > 4)
                      Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: const BoxDecoration(
                            color: _kMuted, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text('+${item.payerIds.length - 4}',
                            style: const TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      '${item.payerIds.length} people',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: _kMuted),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: _kCream,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        '฿${item.pricePerPayer.toStringAsFixed(0)}/person',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _kPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      color: _kMuted, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── QR section ────────────────────────────────────────────────────────────
  Widget _buildQrSection() {
    final hasNewFile = _qrFile != null && _qrBytes != null;
    final hasExistingQr = _existingQrUrl.isNotEmpty;
    final hasQr = hasNewFile || hasExistingQr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('PROMPTPAY QR'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickQr,
          child: Container(
            width: double.infinity,
            height: hasQr ? 200 : 120,
            decoration: BoxDecoration(
              color: hasQr ? Colors.white : _kCream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              painter: _DashBorderPainter(color: hasQr ? _kSuccess : _kPrimary),
              child: hasNewFile
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(_qrBytes!, fit: BoxFit.contain),
                    )
                  : hasExistingQr
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _existingQrUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: _kBorder,
                                size: 48),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.qr_code_2,
                                color: _kPrimary, size: 36),
                            const SizedBox(height: 6),
                            Text('Upload PromptPay QR',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: _kPrimary,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('JPG or PNG',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: _kMuted)),
                          ],
                        ),
            ),
          ),
        ),
        if (hasQr) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.check_circle, color: _kSuccess, size: 14),
            const SizedBox(width: 4),
            Text(
              hasNewFile ? 'Uploaded · tap to change' : 'Existing QR · tap to replace',
              style: GoogleFonts.poppins(fontSize: 11, color: _kSuccess),
            ),
          ]),
        ],
      ],
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar(bool isLoading, double bottomPad) {
    return Container(
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _kBorder))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: _kPrimary,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(children: [
              Text('Total',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 14)),
              const Spacer(),
              Text('฿${_total.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ]),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, bottomPad > 0 ? bottomPad : 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        widget.isEdit
                            ? 'Update bill'
                            : 'Publish bill to members',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecor(String hint,
      {Color fillColor = Colors.white, String? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: _kMuted, fontSize: 13),
      prefixText: prefix,
      prefixStyle: GoogleFonts.poppins(color: _kDark, fontSize: 13),
      filled: true,
      fillColor: fillColor,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
    );
  }
}

// ── Payer selection sheet ─────────────────────────────────────────────────────
class _PayerSheet extends StatefulWidget {
  final String itemName;
  final List<SmartBillMember> members;
  final List<String> selected;

  const _PayerSheet({
    required this.itemName,
    required this.members,
    required this.selected,
  });

  @override
  State<_PayerSheet> createState() => _PayerSheetState();
}

class _PayerSheetState extends State<_PayerSheet> {
  late List<String> _sel;

  @override
  void initState() {
    super.initState();
    _sel = List<String>.from(widget.selected);
  }

  bool get _allSel =>
      widget.members.every((m) => _sel.contains(m.uid));

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.fromLTRB(16, 16, 16, pad + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: _kBorder,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Payers',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kDark)),
                  Text(widget.itemName,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: _kMuted)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                if (_allSel) {
                  _sel.clear();
                } else {
                  _sel =
                      widget.members.map((m) => m.uid).toList();
                }
              }),
              child: Text(
                _allSel ? 'Deselect all' : 'Select all',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: _kPrimary),
              ),
            ),
          ]),
          const Divider(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.members.length,
              itemBuilder: (_, i) {
                final m = widget.members[i];
                final isSel = _sel.contains(m.uid);
                return CheckboxListTile(
                  value: isSel,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _sel.add(m.uid);
                    } else {
                      _sel.remove(m.uid);
                    }
                  }),
                  title: Text(m.name,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: _kDark)),
                  secondary: CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        _kAvatarColors[i % _kAvatarColors.length],
                    child: Text(m.initials.substring(0, 1),
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                  activeColor: _kPrimary,
                  checkColor: Colors.white,
                  dense: true,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_sel),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: Text(
                'Confirm (${_sel.length} people)',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────
class _BillAppBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _BillAppBar({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kPrimary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: 56,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              onPressed: () => context.pop(),
            ),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color valueColor;

  const _StatCell({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor = _kDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight:
                      bold ? FontWeight.w700 : FontWeight.w600,
                  color: valueColor),
              textAlign: TextAlign.center),
          const SizedBox(height: 1),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 10, color: _kMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _kMuted,
          letterSpacing: 0.9));
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder)),
        child: Center(
            child: Text(text,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: _kMuted))),
      );
}

// ── Dashed border painter ─────────────────────────────────────────────────────
class _DashBorderPainter extends CustomPainter {
  final Color color;
  const _DashBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 4.0;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(12)));
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(
            m.extractPath(d, math.min(d + dash, m.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashBorderPainter old) =>
      old.color != color;
}
