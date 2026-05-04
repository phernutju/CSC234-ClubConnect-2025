import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/community_model.dart';
import '../../../models/rule_model.dart';
import '../../../providers/community_provider.dart';

/// Second step of the join flow.
/// Shows the community rules list, an accept checkbox, and a Join button.
/// The Join button is disabled until the checkbox is checked.
/// On join: increments member count in [CommunityProvider], closes this modal,
/// then fires [onJoined] so the parent can navigate to the chat page.
class CommunityRulesModal extends StatefulWidget {
  final CommunityModel community;
  final VoidCallback onJoined;

  const CommunityRulesModal({
    super.key,
    required this.community,
    required this.onJoined,
  });

  @override
  State<CommunityRulesModal> createState() => _CommunityRulesModalState();
}

class _CommunityRulesModalState extends State<CommunityRulesModal> {
  bool _accepted = false;

  void _onJoin() {
    context.read<CommunityProvider>().joinCommunity(widget.community.id);
    Navigator.of(context).pop();
    widget.onJoined();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.rateModalRadius)),
      ),
      clipBehavior: Clip.hardEdge,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: SizedBox(
        width: AppSizes.communityModalWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Coral top banner with X button ────────────────────────────
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: AppSizes.rulesBannerHeight,
                  color: AppColors.primary,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                  ),
                  child: Text(
                    AppStrings.rulesModalTitle,
                    style: AppTextStyles.poppins(
                      fontSize: AppSizes.fontXXVI,
                      color: AppColors.cardWhite,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Positioned(
                  top: AppSizes.paddingS,
                  right: AppSizes.paddingS,
                  child: _CloseButton(
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),

            // ── White scrollable rules + accept checkbox ───────────────────
            Container(
              color: AppColors.cardWhite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        AppSizes.rulesContentPadH,
                        AppSizes.rulesContentPadV,
                        AppSizes.rulesContentPadH,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rules list
                          ...widget.community.rules.asMap().entries.map(
                            (e) => _RuleItem(index: e.key + 1, rule: e.value),
                          ),
                          SizedBox(height: AppSizes.rulesPreCheckboxGap),

                          // Accept rules checkbox + label
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _accepted = !_accepted),
                                child: Container(
                                  width: AppSizes.rulesCheckboxSize,
                                  height: AppSizes.rulesCheckboxSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.rulesCheckboxRadius,
                                    ),
                                    border: Border.all(
                                        color: AppColors.commentBody),
                                    color: _accepted
                                        ? AppColors.primary
                                        : AppColors.cardWhite,
                                  ),
                                  child: _accepted
                                      ? const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: AppColors.cardWhite,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: AppSizes.paddingS),
                              Expanded(
                                child: Text(
                                  AppStrings.rulesAcceptLabel,
                                  style: AppTextStyles.poppins(
                                    fontSize: AppSizes.fontXS,
                                    color: AppColors.commentBody,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSizes.rulesPreButtonGap),
                        ],
                      ),
                    ),
                  ),

                  // ── Join button ────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSizes.rulesContentPadH,
                      0,
                      AppSizes.rulesContentPadH,
                      AppSizes.rulesContentPadV,
                    ),
                    child: Center(
                      child: GestureDetector(
                        onTap: _accepted ? _onJoin : null,
                        child: Container(
                          width: AppSizes.modalActionButtonWidth,
                          height: AppSizes.modalActionButtonHeight,
                          decoration: BoxDecoration(
                            color: _accepted
                                ? AppColors.primary
                                : AppColors.rateCardBorder,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusPill),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            AppStrings.rulesJoinButton,
                            style: AppTextStyles.poppins(
                              fontSize: AppSizes.fontTitle,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cardWhite,
                            ),
                          ),
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
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

/// One rule entry: "[N].[Title]" + description text below.
class _RuleItem extends StatelessWidget {
  final int index;
  final RuleModel rule;

  const _RuleItem({required this.index, required this.rule});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.rulesItemGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index.${rule.text}',
            style: AppTextStyles.poppins(
              fontSize: AppSizes.fontML,
              color: AppColors.textDark,
            ),
          ),
          
        ],
      ),
    );
  }
}

/// White circle with × — dismisses the modal.
class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSizes.rateCloseButtonSize,
        height: AppSizes.rateCloseButtonSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.cardWhite,
        ),
        child: const Icon(Icons.close, size: 16, color: AppColors.textDark),
      ),
    );
  }
}
