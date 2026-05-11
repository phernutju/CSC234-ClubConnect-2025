import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';
import '../widgets/step_progress_bar.dart';

// ── Screen ─────────────────────────────────────────────────────────────────────

/// Step 5 of 5 in the onboarding flow.
/// User must tick the agreement checkbox before "Accept & Continue" unlocks.
class CommunityStandardsScreen extends StatefulWidget {
  const CommunityStandardsScreen({super.key});

  @override
  State<CommunityStandardsScreen> createState() =>
      _CommunityStandardsScreenState();
}

class _CommunityStandardsScreenState extends State<CommunityStandardsScreen> {
  /// Tracks whether the user has ticked the agreement checkbox.
  bool hasAgreedToPolicy = false;

  /// Derived from [hasAgreedToPolicy] — gates the primary button.
  bool get isAgreementButtonEnabled => hasAgreedToPolicy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        minimum: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            // ── Scrollable body ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    const StepProgressBar(currentStep: 5),
                    const SizedBox(height: AppSizes.paddingL),

                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingM),

                    Text(
                      AppStrings.communityStandardsTitle,
                      style: AppTextStyles.title(
                        fontSize: 36.0,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingXS),

                    Text(
                      AppStrings.communityStandardsSubtitle,
                      style: AppTextStyles.poppins(
                        fontSize: 13.0,
                        color: AppColors.textGray,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingL),

                    const PolicyRulesList(),
                    const SizedBox(height: AppSizes.paddingL),

                    AgreementCheckbox(
                      value: hasAgreedToPolicy,
                      onChanged: (v) =>
                          setState(() => hasAgreedToPolicy = v),
                    ),
                    const SizedBox(height: AppSizes.paddingXL),
                  ],
                ),
              ),
            ),

            // ── Fixed bottom buttons ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingL,
                0,
                AppSizes.paddingL,
                AppSizes.paddingXL,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary: enabled only when checkbox is ticked.
                  SizedBox(
                    height: AppSizes.buttonHeight,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isAgreementButtonEnabled
                          ? () => context.go('/home')
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.stepInactive,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                      ),
                      child: Text(
                        AppStrings.communityStandardsAccept,
                        style: AppTextStyles.button(color: AppColors.cardWhite),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingXS),

                  // Secondary: low-emphasis plain text, goes back to landing page.
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: Text(
                      AppStrings.communityStandardsDecline,
                      style: AppTextStyles.body(
                        fontSize: AppSizes.fontSM,
                        color: AppColors.textGray,
                      ),
                    ),
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

// ── Policy rules list ──────────────────────────────────────────────────────────

/// Renders the 7 platform policy rules inside a white card.
/// Rules are separated by thin dividers; numbers are plain muted gray text.
class PolicyRulesList extends StatelessWidget {
  const PolicyRulesList({super.key});

  static const _rules = [
    AppStrings.communityStandardsRule1,
    AppStrings.communityStandardsRule2,
    AppStrings.communityStandardsRule3,
    AppStrings.communityStandardsRule4,
    AppStrings.communityStandardsRule5,
    AppStrings.communityStandardsRule6,
    AppStrings.communityStandardsRule7,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: AppColors.rateCardBorder),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _rules.length; i++) ...[
            _PolicyRuleItem(number: i + 1, label: _rules[i]),
            // Divider between rows only — not after the last item.
            if (i < _rules.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.divider,
              ),
          ],
        ],
      ),
    );
  }
}

/// Single row: muted gray number on the left, rule text on the right.
class _PolicyRuleItem extends StatelessWidget {
  final int number;
  final String label;

  const _PolicyRuleItem({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Plain number — no circle, no border, muted gray.
          SizedBox(
            width: AppSizes.paddingL,
            child: Text(
              '$number',
              textAlign: TextAlign.center,
              style: AppTextStyles.poppins(
                fontSize: AppSizes.fontSM,
                fontWeight: FontWeight.w600,
                color: AppColors.textGray,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingM),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.poppins(
                fontSize: AppSizes.fontSM,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Agreement checkbox ─────────────────────────────────────────────────────────

/// Custom checkbox row with tappable "Terms of Service" and
/// "Community Guidelines" inline links.
///
/// Uses [StatefulWidget] so [TapGestureRecognizer]s are properly disposed.
class AgreementCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AgreementCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<AgreementCheckbox> createState() => _AgreementCheckboxState();
}

class _AgreementCheckboxState extends State<AgreementCheckbox> {
  late final TapGestureRecognizer _guidelinesRecognizer;

  @override
  void initState() {
    super.initState();
    _guidelinesRecognizer = TapGestureRecognizer()
      ..onTap = () {
        // TODO: open Community Guidelines page
      };
  }

  @override
  void dispose() {
    _guidelinesRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bodyColor =
        widget.value ? AppColors.primary : AppColors.commentBody;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom checkbox box
        GestureDetector(
          onTap: () => widget.onChanged(!widget.value),
          child: Container(
            width: AppSizes.rulesCheckboxSize,
            height: AppSizes.rulesCheckboxSize,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(AppSizes.rulesCheckboxRadius),
              border: Border.all(color: bodyColor),
              color:
                  widget.value ? Colors.transparent : AppColors.cardWhite,
            ),
            child: widget.value
                ? const Icon(
                    Icons.check,
                    size: 12,
                    color: AppColors.primary,
                  )
                : null,
          ),
        ),
        const SizedBox(width: AppSizes.paddingS),

        // Agreement text — "Community Guidelines" is a tappable accent link.
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppTextStyles.poppins(
                fontSize: AppSizes.fontXS,
                color: bodyColor,
              ),
              children: [
                const TextSpan(
                  text: AppStrings.communityStandardsAgreementPrefix,
                ),
                TextSpan(
                  text: AppStrings.communityStandardsGuidelinesLink,
                  style: AppTextStyles.poppins(
                    fontSize: AppSizes.fontXS,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  recognizer: _guidelinesRecognizer,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
