import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CartFlyAnimation {
  static void run({
    required BuildContext context,
    required GlobalKey sourceKey,
    required GlobalKey targetKey,
    required String imageUrl,
    VoidCallback? onComplete,
  }) {
    final overlay = Overlay.of(context);
    final renderSource = sourceKey.currentContext?.findRenderObject() as RenderBox?;
    final renderTarget = targetKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderSource == null || renderTarget == null) {
      onComplete?.call();
      return;
    }

    final startOffset = renderSource.localToGlobal(
      Offset(renderSource.size.width / 2, renderSource.size.height / 2),
    );
    final endOffset = renderTarget.localToGlobal(
      Offset(renderTarget.size.width / 2, renderTarget.size.height / 2),
    );

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (ctx) => _FlyWidget(
        startOffset: startOffset,
        endOffset: endOffset,
        imageUrl: imageUrl,
        onFinished: () {
          try {
            overlayEntry.remove();
          } catch (_) {}
          onComplete?.call();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _FlyWidget extends StatefulWidget {
  final Offset startOffset;
  final Offset endOffset;
  final String imageUrl;
  final VoidCallback onFinished;

  const _FlyWidget({
    required this.startOffset,
    required this.endOffset,
    required this.imageUrl,
    required this.onFinished,
  });

  @override
  State<_FlyWidget> createState() => _FlyWidgetState();
}

class _FlyWidgetState extends State<_FlyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value;

        // Quadratic Bezier arc with upward parabolic peak
        final p0 = widget.startOffset;
        final p2 = widget.endOffset;
        final p1 = Offset(
          p0.dx + (p2.dx - p0.dx) * 0.4,
          math.min(p0.dy, p2.dy) - 90,
        );

        final currentX = math.pow(1 - t, 2) * p0.dx +
            2 * (1 - t) * t * p1.dx +
            math.pow(t, 2) * p2.dx;
        final currentY = math.pow(1 - t, 2) * p0.dy +
            2 * (1 - t) * t * p1.dy +
            math.pow(t, 2) * p2.dy;

        // Scale: pops up slightly then shrinks gracefully as it enters cart
        final scale = t < 0.2
            ? 1.0 + (t / 0.2) * 0.25
            : (1.25 - ((t - 0.2) / 0.8) * 0.95).clamp(0.2, 1.25);

        // Rotation: slight spin
        final rotation = (t * math.pi * 0.7) - 0.2;

        // Opacity: fades out cleanly as it lands
        final opacity = t > 0.9 ? (1.0 - (t - 0.9) / 0.1).clamp(0.0, 1.0) : 1.0;

        const size = 48.0;

        return Positioned(
          left: currentX - (size / 2),
          top: currentY - (size / 2),
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Transform.rotate(
                  angle: rotation,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppColors.accent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: 14,
                          spreadRadius: 3,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: widget.imageUrl.isNotEmpty
                          ? Image.network(
                              widget.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.shopping_bag,
                                color: AppColors.accent,
                                size: 24,
                              ),
                            )
                          : const Icon(
                              Icons.shopping_bag,
                              color: AppColors.accent,
                              size: 24,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
