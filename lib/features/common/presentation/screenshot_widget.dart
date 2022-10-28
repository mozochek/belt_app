import 'dart:typed_data' as td;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScreenshotWidget extends StatelessWidget {
  final Widget child;

  const ScreenshotWidget({
    required this.child,
    super.key,
  });

  static Future<td.ByteData> takeScreenshot(
    BuildContext context, {
    double pixelRatio = 1.0,
  }) async {
    final boundary = context.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) throw UnsupportedError('ScreenshotWidget not found');

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    if (bytes is! td.ByteData) throw UnsupportedError('Error converting image to bytes');

    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: child);
  }
}
