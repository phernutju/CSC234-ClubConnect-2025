import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

// Session-level cache so each URL is downloaded only once.
final _bytesCache = <String, Uint8List>{};

/// Loads an image from Firebase Storage using the SDK (bypasses CORS on Flutter Web).
/// Falls back to a placeholder on error. Returns [SizedBox] for null/empty url.
class NetworkImageView extends StatefulWidget {
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
  State<NetworkImageView> createState() => _NetworkImageViewState();
}

class _NetworkImageViewState extends State<NetworkImageView> {
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load(widget.url);
  }

  @override
  void didUpdateWidget(NetworkImageView old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      setState(() {
        _future = _load(widget.url);
      });
    }
  }

  static Future<Uint8List?> _load(String? url) async {
    if (url == null || url.isEmpty) return null;
    if (_bytesCache.containsKey(url)) return _bytesCache[url];
    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      final bytes = await ref.getData(10 * 1024 * 1024); // 10 MB cap
      if (bytes != null) _bytesCache[url] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url == null || widget.url!.isEmpty) {
      return SizedBox(width: widget.width, height: widget.height);
    }
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          );
        }
        if (snap.data == null) {
          return Container(
            width: widget.width,
            height: widget.height,
            color: AppColors.inputFill,
            child: const Icon(
              Icons.broken_image_outlined,
              color: AppColors.textGray,
              size: 32,
            ),
          );
        }
        return Image.memory(
          snap.data!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (_, __, ___) => Container(
            width: widget.width,
            height: widget.height,
            color: AppColors.inputFill,
            child: const Icon(
              Icons.broken_image_outlined,
              color: AppColors.textGray,
              size: 32,
            ),
          ),
        );
      },
    );
  }
}
