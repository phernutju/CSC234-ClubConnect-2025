import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../services/storage_service.dart';

class CreateEventScreen extends StatefulWidget {
  final String communityId;

  const CreateEventScreen({super.key, required this.communityId});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _nameController     = TextEditingController();
  final _locationController = TextEditingController();
  final _detailController   = TextEditingController();
  final _memberController   = TextEditingController(text: '0');

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Uint8List? _coverBytes;
  bool _isSubmitting = false;
  /// Controls whether the event is publicly visible to all community members.
  bool _isPublished = false;

  // ── Per-field inline error messages — null = no error ────────────────────
  String? _nameError;
  String? _startDateError;
  String? _locationError;
  String? _detailError;
  String? _membersError;

  static const int _nameMax   = 50;
  static const int _detailMax = 500;

  @override
  void dispose() {
    _nameController.dispose();
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
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateError = null; // clear error once a date is picked
      });
    }
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

  /// Checks all required fields; populates per-field errors and returns false
  /// when at least one field is invalid.
  bool _validate() {
    final nameErr = _nameController.text.trim().isEmpty
        ? AppStrings.createEventErrName : null;
    final dateErr = _startDate == null
        ? AppStrings.createEventErrDate : null;
    final locationErr = _locationController.text.trim().isEmpty
        ? AppStrings.createEventErrLocation : null;
    final detailErr = _detailController.text.trim().isEmpty
        ? AppStrings.createEventErrDetail : null;
    final membersErr = (int.tryParse(_memberController.text) ?? 0) < 1
        ? AppStrings.createEventErrMembers : null;

    setState(() {
      _nameError      = nameErr;
      _startDateError = dateErr;
      _locationError  = locationErr;
      _detailError    = detailErr;
      _membersError   = membersErr;
    });

    return nameErr == null &&
        dateErr == null &&
        locationErr == null &&
        detailErr == null &&
        membersErr == null;
  }

  Future<void> _onCreate() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);

    try {
      String coverImageUrl = '';
      if (_coverBytes != null) {
        coverImageUrl = await StorageService()
            .uploadEventImage(_coverBytes!, widget.communityId);
      }

      final memberLimit = int.tryParse(_memberController.text) ?? 0;
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

      final hostName =
          context.read<AppAuthProvider>().user?.displayName ?? '';

      await context.read<EventProvider>().createEvent(
            widget.communityId,
            title: _nameController.text.trim(),
            hostName: hostName,
            startDate: startDateTime,
            endDate: endDateTime,
            location: _locationController.text.trim(),
            detail: _detailController.text.trim(),
            memberLimit: memberLimit,
            coverImageUrl: coverImageUrl,
            isPublished: _isPublished,
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

  /// Snackbar is used only for backend errors and success — not for field validation.
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Card placed directly above the Create button.
  /// Toggling [_isPublished] controls whether the event appears in the feed.
  Widget _buildPublishEventCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: const Color(0xFFE8DFD8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Publish Event',
                  style: AppTextStyles.poppins(
                    fontSize: AppSizes.fontML,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Allow everyone to discover and view this event',
                  style: AppTextStyles.poppins(
                    fontSize: AppSizes.fontXS,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.paddingS),
          // Orange when active
          Switch(
            value: _isPublished,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            onChanged: (bool newValue) => setState(() => _isPublished = newValue),
          ),
        ],
      ),
    );
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
                          errorText: _nameError,
                          onChanged: (_) => setState(() => _nameError = null),
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
                          errorText: _startDateError,
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
                          errorText: _locationError,
                          onChanged: () => setState(() => _locationError = null),
                        ),
                        const SizedBox(height: AppSizes.paddingM),

                        // ── Event Detail ───────────────────────────────────
                        _FieldLabel(AppStrings.createEventDetail),
                        _LimitedTextField(
                          controller: _detailController,
                          hint: AppStrings.createEventDetailHint,
                          maxLength: _detailMax,
                          maxLines: 4,
                          errorText: _detailError,
                          onChanged: (_) => setState(() => _detailError = null),
                        ),
                        const SizedBox(height: AppSizes.paddingM),

                        // ── Members ────────────────────────────────────────
                        _FieldLabel(AppStrings.createEventMembers),
                        _MemberCounter(
                          controller: _memberController,
                          onDecrement: () {
                            final v = int.tryParse(_memberController.text) ?? 0;
                            if (v > 0) {
                              _memberController.text = (v - 1).toString();
                              setState(() => _membersError = null);
                            }
                          },
                          onIncrement: () {
                            final v = int.tryParse(_memberController.text) ?? 0;
                            _memberController.text = (v + 1).toString();
                            setState(() => _membersError = null);
                          },
                          onChanged: (val) {
                            final parsed = int.tryParse(val);
                            final normalized =
                                (parsed == null || parsed < 0) ? '0' : parsed.toString();
                            if (normalized != val) {
                              _memberController.text = normalized;
                              _memberController.selection = TextSelection.collapsed(
                                offset: normalized.length,
                              );
                            }
                            setState(() => _membersError = null);
                          },
                        ),
                        if (_membersError != null) _InlineError(_membersError!),
                        const SizedBox(height: AppSizes.paddingXL),

                        // ── Publish Event toggle ───────────────────────────
                        _buildPublishEventCard(),
                        const SizedBox(height: AppSizes.paddingM),

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
          fontSize: AppSizes.fontML,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Text field with character counter.
/// When [errorText] is non-null the underline turns red and the error is shown
/// inline via [InputDecoration.errorText]; the character counter is hidden.
class _LimitedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const _LimitedTextField({
    required this.controller,
    required this.hint,
    required this.maxLength,
    this.maxLines = 1,
    this.errorText,
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
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w300,
              color: AppColors.fieldPlaceholder,
            ),
            errorText: errorText,
            errorStyle: AppTextStyles.poppins(
              fontSize: AppSizes.fontXS,
              color: Colors.red,
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
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
        // Hide counter while an error is displayed to avoid visual clutter.
        if (errorText == null)
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

/// Text field with a leading icon.
/// When [errorText] is non-null the bottom border and icon turn red and
/// [_InlineError] is rendered below the row.
class _IconTextField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final String? errorText;
  final VoidCallback? onChanged;

  const _IconTextField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor =
        errorText != null ? Colors.red : AppColors.inputBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: errorText != null ? Colors.red : AppColors.textGray,
              ),
              const SizedBox(width: AppSizes.paddingS),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged != null ? (_) => onChanged!() : null,
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
        ),
        if (errorText != null) _InlineError(errorText!),
      ],
    );
  }
}

/// Date / time picker row.
/// When [errorText] is non-null the bottom border and icon turn red and
/// [_InlineError] is rendered below the row.
class _PickerField extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isPlaceholder;
  final VoidCallback onTap;
  final String? errorText;

  const _PickerField({
    required this.icon,
    required this.text,
    required this.isPlaceholder,
    required this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor =
        errorText != null ? Colors.red : AppColors.inputBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: errorText != null ? Colors.red : AppColors.textGray,
                ),
                const SizedBox(width: AppSizes.paddingXS),
                Expanded(
                  child: Text(
                    text,
                    style: AppTextStyles.poppins(
                      fontSize: AppSizes.fontSM,
                      fontWeight:
                          isPlaceholder ? FontWeight.w300 : FontWeight.w400,
                      color: isPlaceholder
                          ? AppColors.fieldPlaceholder
                          : AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) _InlineError(errorText!),
      ],
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

/// Red Poppins text shown directly below a field when validation fails.
class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        message,
        style: AppTextStyles.poppins(
          fontSize: AppSizes.fontXS,
          color: Colors.red,
        ),
      ),
    );
  }
}
