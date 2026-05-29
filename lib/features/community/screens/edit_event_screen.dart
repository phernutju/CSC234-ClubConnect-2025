import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/event_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/event_service.dart';

class EditEventScreen extends StatefulWidget {
  final EventModel event;
  const EditEventScreen({super.key, required this.event});
  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _nameController = TextEditingController();
  final _hostNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _detailController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _memberLimit = 0;
  Uint8List? _coverBytes;
  String _existingCoverUrl = '';
  bool _isClosing = false;

  static const int _nameMax = 50;
  static const int _detailMax = 500;
  static const int _memberMin = 0;
  static const int _memberMax = 999;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.event.title;
    _hostNameController.text = widget.event.createdBy;
    _locationController.text = widget.event.location;
    _detailController.text = widget.event.description;
    _startDate = widget.event.startDate.toDate();
    _endDate = widget.event.endDate.toDate();
    _startTime = TimeOfDay(hour: _startDate!.hour, minute: _startDate!.minute);
    _endTime = TimeOfDay(hour: _endDate!.hour, minute: _endDate!.minute);
    _memberLimit = widget.event.maxAttendees ?? 0;
    _existingCoverUrl = widget.event.imageUrl ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostNameController.dispose();
    _locationController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _coverBytes = bytes);
  }

  ThemeData _datePickerTheme(BuildContext ctx) => Theme.of(ctx).copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(ctx).textTheme),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF6B4A),
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF212121),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF6B4A)),
        ),
      );

  ThemeData _timePickerTheme(BuildContext ctx) => Theme.of(ctx).copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(ctx).textTheme),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF6B4A),
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF6B4A)),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: Colors.white,
          dialBackgroundColor: const Color(0xFFF5F5F5),
          dayPeriodColor: WidgetStateColor.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? const Color(0xFFFF6B4A)
                  : Colors.white),
          dayPeriodTextColor: WidgetStateColor.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? Colors.white
                  : Colors.black),
        ),
      );

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) =>
          Theme(data: _datePickerTheme(ctx), child: child!),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) =>
          Theme(data: _datePickerTheme(ctx), child: child!),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (ctx, child) =>
          Theme(data: _timePickerTheme(ctx), child: child!),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (ctx, child) =>
          Theme(data: _timePickerTheme(ctx), child: child!),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  bool get _isHost {
    final uid = context.read<AppAuthProvider>().user?.uid ?? '';
    return uid.isNotEmpty && widget.event.createdBy == uid;
  }

  Future<void> _onCloseEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Close this event?',
          style: AppTextStyles.poppins(
            fontSize: AppSizes.fontML,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          'This will close the event for all members. This action cannot be undone.',
          style: AppTextStyles.poppins(
            fontSize: AppSizes.fontSM,
            color: AppColors.commentBody,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'No',
              style: AppTextStyles.poppins(
                fontSize: AppSizes.fontSM,
                color: AppColors.textDark,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Yes',
              style: AppTextStyles.poppins(
                fontSize: AppSizes.fontSM,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isClosing = true);
    try {
      await EventService()
          .deleteEvent(widget.event.communityId, widget.event.id);
      if (!mounted) return;
      // pop edit → event_chat → event_detail → events list
      context.pop();
      context.pop();
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to close event: $e');
    } finally {
      if (mounted) setState(() => _isClosing = false);
    }
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack(AppStrings.createEventErrName);
      return;
    }
    if (_startDate == null) {
      _showSnack(AppStrings.createEventErrDate);
      return;
    }

    final st = _startTime ?? const TimeOfDay(hour: 0, minute: 0);
    final et = _endTime ?? st;
    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      st.hour,
      st.minute,
    );
    final endBase = _endDate ?? _startDate!;
    final endDateTime = DateTime(
      endBase.year,
      endBase.month,
      endBase.day,
      et.hour,
      et.minute,
    );

    try {
      await EventService().updateEvent(
        communityId: widget.event.communityId,
        eventId: widget.event.id,
        title: name,
        description: _detailController.text.trim(),
        location: _locationController.text.trim(),
        startDate: Timestamp.fromDate(startDateTime),
        endDate: Timestamp.fromDate(endDateTime),
        maxAttendees: _memberLimit,
        existingImageUrl: _existingCoverUrl.isEmpty ? null : _existingCoverUrl,
        imageBytes: _coverBytes,
      );
      if (!mounted) return;
      _showSnack('Event updated!');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to update event: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      body: Column(
        children: [
          _EditEventAppBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Cover image picker ─────────────────────────────────────
                  _CoverImagePicker(
                    bytes: _coverBytes,
                    existingUrl: _existingCoverUrl,
                    onTap: _pickCoverImage,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingM,
                      vertical: AppSizes.paddingM,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Event Name ───────────────────────────────────────
                        _FieldLabel(AppStrings.createEventName),
                        _LimitedTextField(
                          controller: _nameController,
                          hint: AppStrings.createEventNameHint,
                          maxLength: _nameMax,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppSizes.paddingM),

                        // ── Host Name ────────────────────────────────────────
                        _FieldLabel(AppStrings.createEventHostName),
                        _LimitedTextField(
                          controller: _hostNameController,
                          hint: AppStrings.createEventHostNameHint,
                          maxLength: 50,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppSizes.paddingM),

                        // ── Start Date ───────────────────────────────────────
                        _FieldLabel(AppStrings.createEventStartDate),
                        _PickerField(
                          icon: Icons.calendar_month_outlined,
                          text: _startDate != null
                              ? DateFormat('dd/MM/yyyy').format(_startDate!)
                              : AppStrings.createEventDateHint,
                          isPlaceholder: _startDate == null,
                          onTap: _pickStartDate,
                        ),
                        const SizedBox(height: AppSizes.paddingM),

                        // ── End Date ─────────────────────────────────────────
                        _FieldLabel(AppStrings.createEventEndDate),
                        _PickerField(
                          icon: Icons.calendar_month_outlined,
                          text: _endDate != null
                              ? DateFormat('dd/MM/yyyy').format(_endDate!)
                              : AppStrings.createEventDateHint,
                          isPlaceholder: _endDate == null,
                          onTap: _pickEndDate,
                        ),
                        const SizedBox(height: AppSizes.paddingM),

                        // ── Start Time ───────────────────────────────────────
                        _FieldLabel(AppStrings.createEventStartTime),
                        _PickerField(
                          icon: Icons.access_time_outlined,
                          text: _startTime != null
                              ? _startTime!.format(context)
                              : AppStrings.createEventTimeHint,
                          isPlaceholder: _startTime == null,
                          onTap: _pickStartTime,
                        ),
                        const SizedBox(height: AppSizes.paddingM),

                        // ── End Time ─────────────────────────────────────────
                        _FieldLabel(AppStrings.createEventEndTime),
                        _PickerField(
                          icon: Icons.access_time_outlined,
                          text: _endTime != null
                              ? _endTime!.format(context)
                              : AppStrings.createEventTimeHint,
                          isPlaceholder: _endTime == null,
                          onTap: _pickEndTime,
                        ),
                        const SizedBox(height: AppSizes.paddingM),

                        // ── Location ─────────────────────────────────────────
                        _FieldLabel(AppStrings.createEventLocation),
                        _IconTextField(
                          controller: _locationController,
                          icon: Icons.location_on_outlined,
                          hint: AppStrings.createEventLocationHint,
                        ),
                        const SizedBox(height: AppSizes.paddingM),

                        // ── Event Detail ─────────────────────────────────────
                        _FieldLabel(AppStrings.createEventDetail),
                        _LimitedTextField(
                          controller: _detailController,
                          hint: AppStrings.createEventDetailHint,
                          maxLength: _detailMax,
                          maxLines: 4,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppSizes.paddingM),

                        // ── Members ──────────────────────────────────────────
                        _FieldLabel(AppStrings.createEventMembers),
                        _MemberCounter(
                          value: _memberLimit,
                          min: _memberMin,
                          max: _memberMax,
                          onDecrement: () => setState(() => _memberLimit =
                              (_memberLimit - 1).clamp(_memberMin, _memberMax)),
                          onIncrement: () => setState(() => _memberLimit =
                              (_memberLimit + 1).clamp(_memberMin, _memberMax)),
                        ),
                        const SizedBox(height: AppSizes.paddingXL),

                        // ── Close Event / Save buttons ───────────────────────
                        Row(
                          children: [
                            if (_isHost) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isClosing ? null : _onCloseEvent,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppSizes.radiusPill),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: AppSizes.paddingM),
                                  ),
                                  child: _isClosing
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.red,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Close Event',
                                          style: AppTextStyles.poppins(
                                            fontSize: AppSizes.fontTitle,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.paddingS),
                            ],
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isClosing ? null : _onSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  disabledBackgroundColor:
                                      AppColors.primary.withValues(alpha: 0.6),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.radiusPill),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppSizes.paddingM),
                                ),
                                child: Text(
                                  'Save',
                                  style: AppTextStyles.poppins(
                                    fontSize: AppSizes.fontTitle,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.cardWhite,
                                  ),
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
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _EditEventAppBar extends StatelessWidget {
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
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back, color: AppColors.cardWhite),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Text(
              'Edit Event',
              style: AppTextStyles.body(
                fontSize: AppSizes.fontL,
                fontWeight: FontWeight.bold,
                color: AppColors.cardWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverImagePicker extends StatelessWidget {
  final Uint8List? bytes;
  final String existingUrl;
  final VoidCallback onTap;

  const _CoverImagePicker({
    required this.bytes,
    required this.existingUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageContent;
    if (bytes != null) {
      imageContent = Image.memory(bytes!, fit: BoxFit.cover);
    } else if (existingUrl.isNotEmpty) {
      imageContent = Image.network(existingUrl, fit: BoxFit.cover);
    } else {
      imageContent = Container(color: AppColors.inputFill);
    }

    return Stack(
      children: [
        SizedBox(
          height: AppSizes.coverImageHeight,
          width: double.infinity,
          child: imageContent,
        ),

        // Inner-shadow vignette
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.coverShadowEdge,
                  Colors.transparent,
                  AppColors.coverShadowEdge,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Camera button bottom-right
        Positioned(
          bottom: AppSizes.paddingS,
          right: AppSizes.paddingS,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardWhite,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 18,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Field label — Poppins SemiBold 16px
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppTextStyles.poppins(
          fontSize: AppSizes.fontML,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Text field with character counter — Poppins Light 14px hint
class _LimitedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _LimitedTextField({
    required this.controller,
    required this.hint,
    required this.maxLength,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          onChanged: onChanged,
          buildCounter: (_,
                  {required currentLength, required isFocused, maxLength}) =>
              null,
          style: AppTextStyles.poppins(fontSize: AppSizes.fontSM),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.poppins(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w300,
              color: AppColors.fieldPlaceholder,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 4),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.inputBorder),
            ),
          ),
        ),
        Text(
          '${controller.text.length}/$maxLength',
          style: AppTextStyles.poppins(
            fontSize: AppSizes.fontXXS,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }
}

// Text field with inline icon — icon and field on the same line, bottom border on the row
class _IconTextField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;

  const _IconTextField({
    required this.controller,
    required this.icon,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inputBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.textGray),
          const SizedBox(width: AppSizes.paddingS),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.poppins(fontSize: AppSizes.fontSM),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.poppins(
                  fontSize: AppSizes.fontSM,
                  fontWeight: FontWeight.w300,
                  color: AppColors.fieldPlaceholder,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Date / time picker row — Poppins Light 14px placeholder
class _PickerField extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isPlaceholder;
  final VoidCallback onTap;

  const _PickerField({
    required this.icon,
    required this.text,
    required this.isPlaceholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.inputBorder)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textGray),
            const SizedBox(width: AppSizes.paddingXS),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.poppins(
                  fontSize: AppSizes.fontSM,
                  fontWeight: isPlaceholder ? FontWeight.w300 : FontWeight.w400,
                  color: isPlaceholder
                      ? AppColors.fieldPlaceholder
                      : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberCounter extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _MemberCounter({
    required this.value,
    required this.min,
    required this.max,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CounterButton(
            icon: Icons.remove, onTap: value > min ? onDecrement : null),
        const SizedBox(width: AppSizes.paddingM),
        Text(
          value.toString(),
          style: AppTextStyles.poppins(
            fontSize: AppSizes.fontL,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSizes.paddingM),
        _CounterButton(
            icon: Icons.add, onTap: value < max ? onIncrement : null),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CounterButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : const Color(0xFFBDBDBD),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? AppColors.cardWhite : const Color(0xFF757575)),
      ),
    );
  }
}
