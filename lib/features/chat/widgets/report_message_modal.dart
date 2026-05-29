import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Opens the report modal as a dialog overlay.
/// The chat page stays visible (dimmed) behind the modal.
void showReportModal(
  BuildContext context, {
  required String reportedUsername,
  required String communityName,
  required String messageSnippet,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => ReportMessageModal(
      reportedUsername: reportedUsername,
      communityName: communityName,
      messageSnippet: messageSnippet,
    ),
  );
}

// ── Modal widget ──────────────────────────────────────────────────────────────

/// The full report dialog.  Stateful because the user can select a reason chip.
class ReportMessageModal extends StatefulWidget {
  final String reportedUsername;
  final String communityName;
  final String messageSnippet;

  const ReportMessageModal({
    super.key,
    required this.reportedUsername,
    required this.communityName,
    required this.messageSnippet,
  });

  @override
  State<ReportMessageModal> createState() => _ReportMessageModalState();
}

class _ReportMessageModalState extends State<ReportMessageModal> {
  String? _selectedReason;
  final _descController = TextEditingController();

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      // Minimal inset so the fixed-size modal stays away from screen edges
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingL,
      ),
      child: SizedBox(
        width: AppSizes.reportModalWidth,
        height: AppSizes.reportModalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Modal body — scrollable so it never overflows on small screens ──
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title: "Why are you" (Instrument Serif) + italic coral "Report"
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${AppStrings.reportTitle} ',
                            style: AppTextStyles.title(
                              fontSize: AppSizes.fontXL,
                              fontWeight: FontWeight.normal,
                              color: AppColors.textDark,
                            ),
                          ),
                          TextSpan(
                            text: AppStrings.reportTitleAccent,
                            style: AppTextStyles.title(
                              fontSize: AppSizes.fontXL,
                              fontWeight: FontWeight.normal,
                              fontStyle: FontStyle.italic,
                              color: AppColors.reportAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingXS),

                    // Subtitle — Inter Regular, muted gray
                    Text(
                      AppStrings.reportSubtitle,
                      style: AppTextStyles.body(
                        fontSize: AppSizes.fontXS,
                        color: AppColors.reportSubtitleGray,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingS),

                    // Reported user info card
                    _UserInfoCard(
                      username: widget.reportedUsername,
                      communityName: widget.communityName,
                      messageSnippet: widget.messageSnippet,
                    ),
                    const SizedBox(height: AppSizes.paddingS),

                    // "Reason" label — Poppins Regular
                    Text(
                      AppStrings.reportReasonLabel,
                      style: AppTextStyles.poppins(
                        fontSize: AppSizes.fontS,
                        color: AppColors.reportLabelGray,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingS),

                    // Reason chips: unselected = outlined, selected = black fill
                    Wrap(
                      spacing: AppSizes.paddingS,
                      runSpacing: AppSizes.paddingXS,
                      children: AppStrings.reportReasons.map((reason) {
                        final isSelected = _selectedReason == reason;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedReason = reason),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingM,
                              vertical: AppSizes.paddingXS,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.textDark
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(64),
                              border: Border.all(color: AppColors.textDark),
                            ),
                            child: Text(
                              reason,
                              style: AppTextStyles.poppins(
                                fontSize: AppSizes.fontXS,
                                color: isSelected
                                    ? AppColors.cardWhite
                                    : AppColors.textDark,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSizes.paddingS),

                    // "Description" label — Poppins Regular
                    Text(
                      AppStrings.reportDescriptionLabel,
                      style: AppTextStyles.poppins(
                        fontSize: AppSizes.fontS,
                        color: AppColors.reportLabelGray,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingXS),

                    // Description text field — white bg, #E8DFD8 stroke, radius 8, h36
                    SizedBox(
                      height: AppSizes.reportDescFieldHeight,
                      child: TextField(
                        controller: _descController,
                        maxLines: 1,
                        style: AppTextStyles.body(
                          fontSize: AppSizes.fontS,
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.reportDescriptionHint,
                          hintStyle: AppTextStyles.poppins(
                            fontSize: AppSizes.fontS,
                            color: AppColors.textGray,
                          ),
                          filled: true,
                          fillColor: AppColors.cardWhite,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingM,
                            vertical: AppSizes.paddingS,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusS),
                            borderSide: const BorderSide(
                                color: AppColors.reportFieldBg),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusS),
                            borderSide: const BorderSide(
                                color: AppColors.reportFieldBg),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusS),
                            borderSide: const BorderSide(
                                color: AppColors.reportFieldBg),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingS),

                    // "Post" button — full width, coral, Poppins SemiBold, radius 32
                    SizedBox(
                      width: double.infinity,
                      height: AppSizes.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.reportAccent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusXL),
                          ),
                        ),
                        child: Text(
                          AppStrings.reportPost,
                          style: AppTextStyles.poppins(
                            fontSize: AppSizes.fontM,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cardWhite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ), // SingleChildScrollView

            // ── X close button (coral circle, top-right corner) ─────────────
            Positioned(
              top: -AppSizes.paddingM,
              right: -AppSizes.paddingM,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.reportAccent,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.cardWhite,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reported user info card ───────────────────────────────────────────────────

/// Bordered card showing the avatar, username, community, and message snippet.
class _UserInfoCard extends StatelessWidget {
  final String username;
  final String communityName;
  final String messageSnippet;

  const _UserInfoCard({
    required this.username,
    required this.communityName,
    required this.messageSnippet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Row(
        children: [
          // Salmon avatar
          Container(
            width: AppSizes.avatarSmall,
            height: AppSizes.avatarSmall,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.avatarSalmon,
            ),
          ),
          const SizedBox(width: AppSizes.paddingM),

          // Username + community name + message snippet — Inter Light
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontS,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'from $communityName',
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontXS,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textGray,
                  ),
                ),
                if (messageSnippet.isNotEmpty)
                  Text(
                    '"$messageSnippet"',
                    style: AppTextStyles.body(
                      fontSize: AppSizes.fontXS,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
