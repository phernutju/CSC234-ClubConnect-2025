import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Gradient/cover header shown in Edit Profile mode.
/// The cover band is tappable to replace with a photo from the gallery.
/// The avatar circle also has a camera-icon overlay for picking a profile picture.
class EditProfileHeader extends StatelessWidget {
  final Uint8List? avatarBytes;
  final VoidCallback onAvatarTap;
  final Uint8List? coverBytes;
  final String? coverUrl;
  final VoidCallback onCoverTap;

  const EditProfileHeader({
    super.key,
    required this.avatarBytes,
    required this.onAvatarTap,
    required this.coverBytes,
    this.coverUrl,
    required this.onCoverTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.profileHeaderHeight + AppSizes.avatarLarge / 2,
      child: Stack(
        children: [
          // ── Cover band — gradient or selected photo ──────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onCoverTap,
              child: SizedBox(
                height: AppSizes.profileHeaderHeight,
                child: coverBytes != null
                    ? Image.memory(
                        coverBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : (coverUrl != null && coverUrl!.isNotEmpty)
                        ? Image.network(
                            coverUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.profileHeaderStart,
                                  AppColors.profileHeaderEnd,
                                  AppColors.profileHeaderEnd,
                                ],
                                stops: [0.0, 0.44, 0.9],
                              ),
                            ),
                          ),
              ),
            ),
          ),

          // ── Camera icon for cover — top-right corner ─────────────────────
          Positioned(
            top: AppSizes.paddingM,
            right: AppSizes.paddingM,
            child: GestureDetector(
              onTap: onCoverTap,
              child: Container(
                width: AppSizes.profileCameraButtonSize,
                height: AppSizes.profileCameraButtonSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: AppColors.cardWhite,
                  size: 14,
                ),
              ),
            ),
          ),

          // ── Avatar circle with camera overlay ────────────────────────────
          Positioned(
            left: AppSizes.paddingL,
            bottom: 0,
            child: SizedBox(
              width: AppSizes.avatarLarge,
              height: AppSizes.avatarLarge,
              child: Stack(
                children: [
                  Container(
                    width: AppSizes.avatarLarge,
                    height: AppSizes.avatarLarge,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.avatarSalmon,
                      border: Border.all(color: AppColors.cardWhite, width: 3),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: avatarBytes != null
                        ? Image.memory(avatarBytes!, fit: BoxFit.cover)
                        : null,
                  ),

                  // Coral camera button — bottom-right of avatar
                  Positioned(
                    right: 0,
                    bottom: 4,
                    child: GestureDetector(
                      onTap: onAvatarTap,
                      child: Container(
                        width: AppSizes.profileCameraButtonSize,
                        height: AppSizes.profileCameraButtonSize,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: AppColors.cardWhite,
                          size: 14,
                        ),
                      ),
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
