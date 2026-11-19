import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';

/// Static PekSoft Radio Browser brand logo mark (all signal waves illuminated)
/// for headers and branding alongside text.
class PekSoftLogoMark extends StatelessWidget {
  const PekSoftLogoMark({
    super.key,
    this.size = 32,
    this.showBackground = true,
  });

  final double size;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PekSoftSignalPainter(
        progress: 0.5,
        showBackground: showBackground,
      ),
    );
  }
}

/// Custom PekSoft Radio Browser loading indicator:
/// Centered brand logo with the three yellow signal elements animated in
/// sequence like a radio searching for signal:
///   1) Small dot appears first -> inner arc -> outer (largest) arc
///   2) Outer (largest) arc disappears first -> inner arc -> small dot
class PekSoftSignalLoader extends StatefulWidget {
  const PekSoftSignalLoader({
    super.key,
    this.size = 72,
    this.label = 'Searching for signal…',
    this.showBackground = true,
  });

  final double size;
  final String? label;
  final bool showBackground;

  @override
  State<PekSoftSignalLoader> createState() => _PekSoftSignalLoaderState();
}

class _PekSoftSignalLoaderState extends State<PekSoftSignalLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      liveRegion: true,
      label: widget.label ?? 'Loading',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = disableAnimations ? 0.5 : _controller.value;
              return CustomPaint(
                size: Size.square(widget.size),
                painter: _PekSoftSignalPainter(
                  progress: t,
                  showBackground: widget.showBackground,
                ),
              );
            },
          ),
          if (widget.label != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.label!,
              style: AppTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PekSoftSignalPainter extends CustomPainter {
  const _PekSoftSignalPainter({
    required this.progress,
    required this.showBackground,
  });

  final double progress;
  final bool showBackground;

  double _waveOpacity(double t, double onStart, double onEnd, double offStart, double offEnd) {
    if (t < onStart) return 0.15;
    if (t < onEnd) {
      return 0.15 + 0.85 * ((t - onStart) / (onEnd - onStart));
    }
    if (t < offStart) return 1.0;
    if (t < offEnd) {
      return 1.0 - 0.85 * ((t - offStart) / (offEnd - offStart));
    }
    return 0.15;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512.0;

    if (showBackground) {
      // Background rounded square (#101A2E)
      final bgPaint = Paint()..color = const Color(0xFF101A2E);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(112 * s),
        ),
        bgPaint,
      );
    }

    canvas.save();
    canvas.translate(8 * s, 0);

    // White 'P' stem + bowl (#F4F6FB)
    final whitePaint = Paint()..color = const Color(0xFFF4F6FB);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(152 * s, 136 * s, 48 * s, 240 * s),
        Radius.circular(24 * s),
      ),
      whitePaint,
    );

    final bowlOuter = Path()
      ..moveTo(176 * s, 136 * s)
      ..lineTo(228 * s, 136 * s)
      ..arcTo(
        Rect.fromCircle(center: Offset(228 * s, 212 * s), radius: 76 * s),
        -math.pi / 2,
        math.pi,
        false,
      )
      ..lineTo(176 * s, 288 * s)
      ..close();
    final bowlHole = Path()
      ..moveTo(200 * s, 182 * s)
      ..lineTo(228 * s, 182 * s)
      ..arcTo(
        Rect.fromCircle(center: Offset(228 * s, 212 * s), radius: 30 * s),
        -math.pi / 2,
        math.pi,
        false,
      )
      ..lineTo(200 * s, 242 * s)
      ..close();
    canvas.drawPath(
      Path.combine(PathOperation.difference, bowlOuter, bowlHole),
      whitePaint,
    );

    // 1. Smallest signal (dot): appears 1st, disappears last
    final dotOpacity = _waveOpacity(progress, 0.04, 0.16, 0.80, 0.94);
    final dotPaint = Paint()
      ..color = const Color(0xFFFFB020).withValues(alpha: dotOpacity);
    canvas.drawCircle(Offset(228 * s, 212 * s), 15 * s, dotPaint);

    // 2. Medium signal (inner arc): appears 2nd, disappears 2nd
    final innerOpacity = _waveOpacity(progress, 0.18, 0.32, 0.66, 0.80);
    final innerPaint = Paint()
      ..color = const Color(0xFFFFB020).withValues(alpha: innerOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(228 * s, 212 * s), radius: 104 * s),
      -math.pi / 4,
      math.pi / 2,
      false,
      innerPaint,
    );

    // 3. Largest signal (outer arc): appears 3rd, disappears 1st
    final outerOpacity = _waveOpacity(progress, 0.34, 0.48, 0.52, 0.66);
    final outerPaint = Paint()
      ..color = const Color(0xFFFFB020).withValues(alpha: outerOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(228 * s, 212 * s), radius: 144 * s),
      -math.pi / 4,
      math.pi / 2,
      false,
      outerPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PekSoftSignalPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
