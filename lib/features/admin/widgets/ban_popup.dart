import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/user_service.dart';
import '../models/report_model.dart';

class BanPopup extends StatefulWidget {
  final AdminReportModel report;

  const BanPopup({super.key, required this.report});

  static void show(BuildContext context, AdminReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BanPopup(report: report),
    );
  }

  @override
  State<BanPopup> createState() => _BanPopupState();
}

class _BanPopupState extends State<BanPopup> {
  final Set<String> _selectedReasons = {};
  String? _selectedDuration;
  final _descController = TextEditingController();
  bool _isBanning = false;

  static const _reasons = ['Hate Speech', 'Harassment', 'Scam', 'Threat', 'Others'];
  static const _durations = ['Permanently', '1 Month', '7 Days', '24 hours', '12 hours', '6 hours', '1 hours'];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (widget.report.targetUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot ban: no target user ID available.')),
      );
      Navigator.pop(context);
      return;
    }

    final reasonText = _selectedReasons.isNotEmpty
        ? _selectedReasons.join(', ')
        : _descController.text.trim();
    final description = reasonText.isNotEmpty ? reasonText : 'Violation of community guidelines';

    setState(() => _isBanning = true);
    try {
      await UserService.banUser(widget.report.targetUserId, description);
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
          SnackBar(content: Text('Failed to ban user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 24, 20, bottomInset + 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5E5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    '.claude/traffic.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.block, color: Colors.red, size: 36),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Do you want to\nban this user?',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ReportInfoCard(report: widget.report),
            const SizedBox(height: 20),
            Text(
              'REASON',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reasons.map((r) {
                final selected = _selectedReasons.contains(r);
                return _Chip(
                  label: r,
                  selected: selected,
                  onTap: () => setState(() {
                    selected ? _selectedReasons.remove(r) : _selectedReasons.add(r);
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF000000)),
              decoration: InputDecoration(
                hintText: 'Ban Description...',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF797979)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'BAN DURATION',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durations.map((d) {
                final selected = _selectedDuration == d;
                return _Chip(
                  label: d,
                  selected: selected,
                  onTap: () => setState(() => _selectedDuration = d),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Dismiss',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF000000),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isBanning ? null : _onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6868),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(color: Color(0xFFFF6868)),
                      ),
                    ),
                    child: _isBanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Confirm ban',
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
          ],
        ),
      ),
    );
  }
}

class _BanIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      '.claude/traffic.png',
      width: 64,
      height: 64,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.block,
        color: Colors.red,
        size: 64,
      ),
    );
  }
}

class _ReportInfoCard extends StatelessWidget {
  final AdminReportModel report;
  const _ReportInfoCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DFD8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REPORT NO.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF797979),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            report.id,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'SOURCE',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF797979),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            report.source,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF000000) : Colors.white,
          border: Border.all(color: const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.0,
            letterSpacing: 0,
            color: selected ? Colors.white : const Color(0xFF000000),
          ),
        ),
      ),
    );
  }
}
