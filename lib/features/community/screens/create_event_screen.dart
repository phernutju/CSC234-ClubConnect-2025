import 'dart:typed_data';
import 'package:csc234_clubconnect/models/category_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/event_provider.dart';
import '../../../services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateEventScreen extends StatefulWidget {
  final String communityId;

  const CreateEventScreen({super.key, required this.communityId});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _nameController     = TextEditingController();
  final _hostNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _detailController   = TextEditingController();
  final _memberController   = TextEditingController(text: '0');

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Uint8List? _coverBytes;
  bool _isSubmitting = false;

  static const int _nameMax   = 50;
  static const int _detailMax = 500;

  @override
  void dispose() {
    _nameController.dispose();
    _hostNameController.dispose();
    _locationController.dispose();
    _detailController.dispose();
    _memberController.dispose();
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
              states.contains(WidgetState.selected) ? const Color(0xFFFF6B4A) : Colors.white),
          dayPeriodTextColor: WidgetStateColor.resolveWith((states) =>
              states.contains(WidgetState.selected) ? Colors.white : Colors.black),
        ),
      );

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(data: _datePickerTheme(ctx), child: child!),
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
      builder: (ctx, child) => Theme(data: _datePickerTheme(ctx), child: child!),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (ctx, child) => Theme(data: _timePickerTheme(ctx), child: child!),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (ctx, child) => Theme(data: _timePickerTheme(ctx), child: child!),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _onCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack(AppStrings.createEventErrName);
      return;
    }
    if (_startDate == null) {
      _showSnack(AppStrings.createEventErrDate);
      return;
    }

    setState(() => _isSubmitting = true);
    final ep = context.read<EventProvider>();

    try {
      String coverImageUrl = '';
      if (_coverBytes != null) {
        coverImageUrl = await StorageService()
            .uploadEventImage(_coverBytes!, widget.communityId);
      }

      final st = _startTime ?? const TimeOfDay(hour: 0, minute: 0);
      final et = _endTime ?? st;
      final startDateTime = DateTime(
        _startDate!.year, _startDate!.month, _startDate!.day,
        st.hour, st.minute,
      );
      final endBase = _endDate ?? _startDate!;
      final endDateTime = DateTime(
        endBase.year, endBase.month, endBase.day,
        et.hour, et.minute,
      );

      final memberLimit = int.tryParse(_memberController.text) ?? 0;

      await ep.createEvent(
            communityId: widget.communityId,
            title: name,
            description: _detailController.text.trim(),
            location: _locationController.text.trim(),
            tags: const [],
            startDate: Timestamp.fromDate(startDateTime),
            endDate: Timestamp.fromDate(endDateTime),
            roomId: widget.communityId,
            imageUrl: coverImageUrl.isEmpty ? null : coverImageUrl,
            maxAttendees: memberLimit,
          );

      if (!mounted) return;
      if (ep.error != null) {
        _showSnack(ep.error!);
      } else {
        _showSnack(AppStrings.createEventSuccess);
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          _CreateEventAppBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Cover image picker ───────────────────────────────────
                  _CoverImagePicker(
                    bytes: _coverBytes,
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
                        // ── Event Name ─────────────────────────────────────
                        _FieldLabel(AppStrings.createEventName),
                        _LimitedTextField(
                          controller: _nameController,
                          hint: AppStrings.createEventNameHint,
                          maxLength: _nameMax,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppSizes.paddingM),

                        // ── Host Name ──────────────────────────────────────
                        _FieldLabel(AppStrings.createEventHostName),
                        _LimitedTextField(
                          controller: _hostNameController,
                          hint: AppStrings.createEventHostNameHint,
                          maxLength: 50,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppSizes.paddingM),

                        // ── Start Date ─────────────────────────────────────
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

                        // ── End Date ───────────────────────────────────────
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

                        // ── Start Time ─────────────────────────────────────
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

                        // ── End Time ───────────────────────────────────────
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

                        // ── Location ───────────────────────────────────────
                        _FieldLabel(AppStrings.createEventLocation),
                        _IconTextField(
                          controller: _locationController,
                          icon: Icons.location_on_outlined,
                          hint: AppStrings.createEventLocationHint,
                        ),
                        const SizedBox(height: AppSizes.paddingM),

                        // ── Event Detail ───────────────────────────────────
                        _FieldLabel(AppStrings.createEventDetail),
                        _LimitedTextField(
                          controller: _detailController,
                          hint: AppStrings.createEventDetailHint,
                          maxLength: _detailMax,
                          maxLines: 4,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppSizes.paddingM),

                        // ── Members ────────────────────────────────────────
                        _FieldLabel(AppStrings.createEventMembers),
                        _MemberCounter(
                          controller: _memberController,
                          onDecrement: () {
                            final v = int.tryParse(_memberController.text) ?? 0;
                            if (v > 0) _memberController.text = (v - 1).toString();
                          },
                          onIncrement: () {
                            final v = int.tryParse(_memberController.text) ?? 0;
                            _memberController.text = (v + 1).toString();
                          },
                          onChanged: (val) {
                            final parsed = int.tryParse(val);
                            if (parsed == null || parsed < 0) {
                              _memberController.text = '0';
                              _memberController.selection = TextSelection.collapsed(
                                offset: _memberController.text.length,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: AppSizes.paddingXL),

                        // ── Create button ──────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _onCreate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: AppColors.cardWhite,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    AppStrings.createEventButton,
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

class _CreateEventAppBar extends StatelessWidget {
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
              AppStrings.createEventTitle,
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
  final VoidCallback onTap;

  const _CoverImagePicker({required this.bytes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: AppSizes.coverImageHeight,
          width: double.infinity,
          child: bytes != null
              ? Image.memory(bytes!, fit: BoxFit.cover)
              : Container(color: AppColors.inputFill),
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
          fontSize: AppSizes.fontML,     // 16px
          fontWeight: FontWeight.w600,   // SemiBold
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
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
          style: AppTextStyles.poppins(fontSize: AppSizes.fontSM),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.poppins(
              fontSize: AppSizes.fontSM,     // 14px
              fontWeight: FontWeight.w300,   // Light
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
                  fontSize: AppSizes.fontSM,                                   // 14px
                  fontWeight: isPlaceholder ? FontWeight.w300 : FontWeight.w400, // Light if placeholder
                  color: isPlaceholder ? AppColors.fieldPlaceholder : AppColors.textDark,
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
  final TextEditingController controller;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<String> onChanged;

  const _MemberCounter({
    required this.controller,
    required this.onDecrement,
    required this.onIncrement,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CounterButton(icon: Icons.remove, onTap: onDecrement),
        const SizedBox(width: AppSizes.paddingM),
        SizedBox(
          width: 56,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: onChanged,
            style: AppTextStyles.poppins(
              fontSize: AppSizes.fontL,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.only(bottom: 4),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.inputBorder),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.inputBorder),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.paddingM),
        _CounterButton(icon: Icons.add, onTap: onIncrement),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CounterButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.cardWhite),
      ),
    );
  }
}
