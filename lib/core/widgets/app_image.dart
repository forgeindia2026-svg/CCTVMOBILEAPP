import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';

class AppImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  static final Map<String, Uint8List> _base64Cache = {};

  const AppImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final raw = imageUrl?.trim() ?? '';
    if (raw.isEmpty) {
      return errorWidget ?? _defaultError();
    }

    // 1. Base64 Data URI (e.g. data:image/png;base64,... or data:image/webp;base64,...)
    if (raw.startsWith('data:image')) {
      try {
        Uint8List? bytes = _base64Cache[raw];
        if (bytes == null) {
          final commaIdx = raw.indexOf(',');
          final base64Str = commaIdx != -1 ? raw.substring(commaIdx + 1) : raw;
          bytes = base64Decode(base64Str.replaceAll(RegExp(r'\s+'), ''));
          _base64Cache[raw] = bytes;
        }
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          gaplessPlayback: true,
          errorBuilder: (ctx, err, stack) => errorWidget ?? _defaultError(),
        );
      } catch (e) {
        return errorWidget ?? _defaultError();
      }
    }

    // 2. Local asset image (e.g. local:wifi_camera.png)
    if (raw.startsWith('local:')) {
      final assetName = raw.split(':')[1];
      return Image.asset(
        'assets/images/$assetName',
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        errorBuilder: (ctx, err, stack) => errorWidget ?? _defaultError(),
      );
    }

    // 3. Asset path directly (assets/images/...)
    if (raw.startsWith('assets/')) {
      return Image.asset(
        raw,
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        errorBuilder: (ctx, err, stack) => errorWidget ?? _defaultError(),
      );
    }

    // 4. Remote HTTP / HTTPS (S3 / Cloud)
    final resolvedUrl = ApiService.resolveImageUrl(raw);
    return Image.network(
      resolvedUrl,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      errorBuilder: (ctx, err, stack) => errorWidget ?? _defaultError(),
    );
  }

  Widget _defaultError() {
    return Container(
      width: width,
      height: height,
      color: Colors.white,
      child: const Center(
        child: Icon(Icons.videocam, color: AppColors.primaryRed, size: 36),
      ),
    );
  }
}
