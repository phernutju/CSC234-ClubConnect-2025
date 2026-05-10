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

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _memberLimit = 0;
  Uint8List? _coverBytes;
  bool _isSubmitting = false;

  static const int _nameMax   = 50;
  static const int _detailMax = 500;
  static const int _memberMin = 0;
  static const int _memberMax = 999;

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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(ctx).textTheme),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFF6B4A),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF212121),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF6B4A),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(ctx).textTheme),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFF6B4A),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF6B4A),
            ),
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Colors.white,
            dialBackgroundColor: const Color(0xFFF5F5F5),
            dayPeriodColor: WidgetStateColor.resolveWith((states) =>
              states.contains(WidgetState.selected)
                ? const Color(0xFFFF6B4A)
                : Colors.white,
            ),
            dayPeriodTextColor: WidgetStateColor.resolveWith((states) =>
              states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.black,
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _onCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack(AppStrings.createEventErrName);
      return;
    }
    if (_selectedDate == null) {
      _showSnack(AppStrings.createEventErrDate);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String coverImageUrl = '';
      if (_coverBytes != null) {
        coverImageUrl = await StorageService()
            .uploadEventImage(_coverBytes!, widget.communityId);
      }

      final time = _selectedTime ?? const TimeOfDay(hour: 0, minute: 0);
      final fullDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        time.hour,
        time.minute,
      );

      await context.read<EventProvider>().createEvent(
            roomId: widget.communityId,
            communityId: widget.communityId,
            title: name,
            startDate: Timestamp.fromDate(fullDate),
            location: _locationController.text.trim(),
            description: _detailController.text.trim(),
            maxAttendees: _memberLimit,
            imageUrl: coverImageUrl,
            tags: List<CategoryModel>.empty(), // TODO: Add category selection  
            endDate: Timestamp.fromDate(fullDate.add(const Duration(hours: 2))), // Default to 2-hour duration
          );

      if (!mounted) return;
      final ep = context.read<EventProvider>();
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

                        // ── Date & Time ────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel(AppStrings.createEventDate),
                                  _PickerField(
                                    icon: Icons.calendar_month_outlined,
                                    text: _selectedDate != null
                                        ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                                        : AppStrings.createEventDateHint,
                                    isPlaceholder: _selectedDate == null,
                                    onTap: _pickDate,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSizes.paddingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel(AppStrings.createEventTime),
                                  _PickerField(
                                    icon: Icons.access_time_outlined,
                                    text: _selectedTime != null
                                        ? _selectedTime!.format(context)
                                        : AppStrings.createEventTimeHint,
                                    isPlaceholder: _selectedTime == null,
                                    onTap: _pickTime,
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                          value: _memberLimit,
                          min: _memberMin,
                          max: _memberMax,
                          onDecrement: () => setState(
                              () => _memberLimit = (_memberLimit - 1).clamp(_memberMin, _memberMax)),
                          onIncrement: () => setState(
                              () => _memberLimit = (_memberLimit + 1).clamp(_memberMin, _memberMax)),
                        ),
                        const SizedBox(height: AppSizes.paddingXL),

                        // ── Create button ──────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _onCreate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
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
        _CounterButton(icon: Icons.remove, onTap: value > min ? onDecrement : null),
        const SizedBox(width: AppSizes.paddingM),
        Text(
          value.toString(),
          style: AppTextStyles.poppins(
            fontSize: AppSizes.fontL,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSizes.paddingM),
        _CounterButton(icon: Icons.add, onTap: value < max ? onIncrement : null),
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
        child: Icon(icon, size: 18, color: enabled ? AppColors.cardWhite : const Color(0xFF757575)),
      ),
    );
  }
}
