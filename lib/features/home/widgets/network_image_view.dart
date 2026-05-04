import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Reusable network image with loading indicator and error fallback.
/// Returns [SizedBox] when [url] is null or empty.
class NetworkImageView extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const NetworkImageView({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = (url?.isNotEmpty == true) ? url! : null;

    if (effectiveUrl == null) {
      return SizedBox(width: width, height: height);
    }

    return Image.network(
      effectiveUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (_, error, _) {
        return Container(
          width: width,
          height: height,
          color: AppColors.inputFill,
          child: const Icon(
            Icons.broken_image_outlined,
            color: AppColors.textGray,
            size: 32,
          ),
        );
      },
    );
  }
}
