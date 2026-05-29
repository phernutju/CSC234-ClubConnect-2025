import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/report_model.dart';
import '../../../providers/report_provider.dart';

// ── Modal widget ──────────────────────────────────────────────────────────────

class ReportUserModal extends StatefulWidget {
  final String username;
  final String communityName;
  final String userId;

  const ReportUserModal({
    super.key,
    required this.username,
    required this.communityName,
    required this.userId,
  });

  @override
  State<ReportUserModal> createState() => _ReportUserModalState();
}

class _ReportUserModalState extends State<ReportUserModal> {
  String? _selectedReason;
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReportProvider>().resetState();
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  ReportReason _reasonToEnum(String label) {
    switch (label) {
      case 'Hate Speech':
        return ReportReason.hateSpeech;
      case 'Harassment':
        return ReportReason.harassment;
      case 'Threat':
        return ReportReason.threat;
      case 'Scam':
        return ReportReason.scam;
      default:
        return ReportReason.other;
    }
  }

  Future<void> _submit() async {
    if (_selectedReason == null) return;
    final rp = context.read<ReportProvider>();
    await rp.submitReport(
      ReportModel(
        reportId: '',
        reporterId: FirebaseAuth.instance.currentUser?.uid ?? '',
        targetUserId: widget.userId,
        communityId: '',
        // use userId as dedup key so one reporter can only report a user once
        messageId: widget.userId,
        messageText: '',
        reason: _reasonToEnum(_selectedReason!),
        targetType: ReportTargetType.user,
        source: ReportSource.user,
        status: ReportStatus.pending,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        createdAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    if (rp.state == ReportState.submitted) {
      Navigator.of(context).pop();
    } else if (rp.state == ReportState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rp.error ?? 'Failed to submit report')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        context.watch<ReportProvider>().state == ReportState.submitting;

    return Dialog(
      backgroundColor: AppColors.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
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
            // ── Modal body ───────────────────────────────────────────────────
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
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

                    Text(
                      AppStrings.reportSubtitle,
                      style: AppTextStyles.body(
                        fontSize: AppSizes.fontXS,
                        color: AppColors.reportSubtitleGray,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingS),

                    _UserInfoCard(
                      username: widget.username,
                      communityName: widget.communityName,
                    ),
                    const SizedBox(height: AppSizes.paddingS),

                    Text(
                      AppStrings.reportReasonLabel,
                      style: AppTextStyles.poppins(
                        fontSize: AppSizes.fontS,
                        color: AppColors.reportLabelGray,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingS),

                    // Reason chips
                    Wrap(
                      spacing: AppSizes.paddingS,
                      runSpacing: AppSizes.paddingXS,
                      children: AppStrings.reportReasons.map((reason) {
                        final isSelected = _selectedReason == reason;
                        return GestureDetector(
                          onTap: isSubmitting
                              ? null
                              : () => setState(() => _selectedReason = reason),
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

                    Text(
                      AppStrings.reportDescriptionLabel,
                      style: AppTextStyles.poppins(
                        fontSize: AppSizes.fontS,
                        color: AppColors.reportLabelGray,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingXS),

                    SizedBox(
                      height: AppSizes.reportDescFieldHeight,
                      child: TextField(
                        controller: _descController,
                        maxLines: 1,
                        enabled: !isSubmitting,
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

                    // Post button
                    SizedBox(
                      width: double.infinity,
                      height: AppSizes.buttonHeight,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.reportAccent,
                          disabledBackgroundColor:
                              AppColors.reportAccent.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusXL),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.cardWhite,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
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
            ),

            // ── X close button ───────────────────────────────────────────────
            Positioned(
              top: -AppSizes.paddingM,
              right: -AppSizes.paddingM,
              child: GestureDetector(
                onTap: isSubmitting ? null : () => Navigator.of(context).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSubmitting
                        ? AppColors.reportAccent.withValues(alpha: 0.6)
                        : AppColors.reportAccent,
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

class _UserInfoCard extends StatelessWidget {
  final String username;
  final String communityName;

  const _UserInfoCard({
    required this.username,
    required this.communityName,
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
          Container(
            width: AppSizes.avatarSmall,
            height: AppSizes.avatarSmall,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.avatarSalmon,
            ),
          ),
          const SizedBox(width: AppSizes.paddingM),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
