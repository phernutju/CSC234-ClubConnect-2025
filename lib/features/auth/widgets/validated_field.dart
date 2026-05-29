import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';

/// A single validation rule: human-readable [label] + pure [validate] function.
/// Set [isLoading] to true while an async check is in flight — the row will
/// show a spinner instead of the pass/fail icon.
class FieldRule {
  final String label;
  final bool Function(String) validate;
  final bool isLoading;
  const FieldRule({
    required this.label,
    required this.validate,
    this.isLoading = false,
  });
}

/// Text field that manages its own [FocusNode] and shows a floating rule-card
/// below the input according to these visibility rules:
///
///  • Hidden while the field is empty (never shame the user on first focus).
///  • Appears on the first keystroke.
///  • Hides automatically once every rule passes (success = silent).
///  • Hides when focus leaves the field.
///  • Only one popup can be visible at a time because only one field can
///    hold focus at a time.
///
/// The card fades in and out over 150 ms. Password fields support a
/// show/hide toggle via [isObscurable].
class ValidatedField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final List<FieldRule> rules;
  final bool isObscurable;
  final TextInputType keyboardType;

  const ValidatedField({
    super.key,
    required this.label,
    required this.controller,
    required this.rules,
    this.isObscurable = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<ValidatedField> createState() => _ValidatedFieldState();
}

class _ValidatedFieldState extends State<ValidatedField> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;
  bool _obscured = true;

  // Two-phase popup lifecycle:
  //  _popupIn    — widget is in the tree (controls space allocation)
  //  _popupVisible — drives AnimatedOpacity (controls opacity 0 ↔ 1)
  // Separating them lets the fade-out complete before the widget is removed.
  bool _popupIn = false;
  bool _popupVisible = false;
  Timer? _hideTimer;

  // Popup should be shown when the field is focused, non-empty, and at least
  // one rule is still failing.
  bool get _wantPopup {
    if (widget.rules.isEmpty) return false;
    final v = widget.controller.text;
    return _hasFocus && v.isNotEmpty && !widget.rules.every((r) => r.validate(v));
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(ValidatedField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rules may have changed (e.g. confirm field when password changes).
    _syncPopup();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _hasFocus = _focusNode.hasFocus);
    _syncPopup();
  }

  void _onTextChanged() {
    setState(() {});
    _syncPopup();
  }

  void _syncPopup() {
    final want = _wantPopup;

    if (want) {
      _hideTimer?.cancel();
      if (!_popupIn) {
        // First appearance: mount at opacity 0, then fade in next frame so
        // AnimatedOpacity can transition from 0 → 1.
        setState(() => _popupIn = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _wantPopup) setState(() => _popupVisible = true);
        });
      } else if (!_popupVisible) {
        // Was mid fade-out — reverse it.
        setState(() => _popupVisible = true);
      }
    } else if (_popupIn) {
      _hideTimer?.cancel();
      setState(() => _popupVisible = false); // start fade-out
      // Remove from tree after animation completes.
      _hideTimer = Timer(const Duration(milliseconds: 160), () {
        if (mounted) setState(() => _popupIn = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.body(
            fontSize: 16.0,
            fontWeight: FontWeight.w300,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppSizes.paddingS),

        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.isObscurable && _obscured,
          keyboardType: widget.keyboardType,
          style: AppTextStyles.body(
            fontSize: 14.0,
            fontWeight: FontWeight.w400,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingM,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            suffixIcon: widget.isObscurable
                ? IconButton(
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textGray,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
          ),
        ),

        // Popup — only mounted while _popupIn is true; opacity driven by
        // _popupVisible so the card fades in and out smoothly.
        if (_popupIn)
          AnimatedOpacity(
            opacity: _popupVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: _RulePopup(rules: widget.rules, value: value),
          ),
      ],
    );
  }
}

// ─── Popup card ───────────────────────────────────────────────────────────────

class _RulePopup extends StatelessWidget {
  final List<FieldRule> rules;
  final String value;

  const _RulePopup({required this.rules, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000), // black @ 8 %
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0, shown = 0; i < rules.length; i++)
            if (rules[i].isLoading || !rules[i].validate(value)) ...[
              if (shown++ > 0) const SizedBox(height: 8),
              _RuleRow(rule: rules[i], value: value),
            ],
        ],
      ),
    );
  }
}

// ─── Single rule row ──────────────────────────────────────────────────────────

class _RuleRow extends StatelessWidget {
  final FieldRule rule;
  final String value;

  const _RuleRow({required this.rule, required this.value});

  static const _green = Color(0xFF43A047);
  static const _red   = Color(0xFFE53935);
  static const _dark  = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final pass = rule.validate(value);
    return Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: rule.isLoading
              ? const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF797979),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: pass ? _green : _red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    pass ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          rule.label,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: rule.isLoading ? _dark : (pass ? _green : _dark),
          ),
        ),
      ],
    );
  }
}
