import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum EmptyIllustration { star, search, noResults }

/// 빈 상태 시안의 얇은 선 아이콘입니다. 크기와 선 색은 제공된 토큰을 씁니다.
class EmptyStateIllustration extends StatelessWidget {
  const EmptyStateIllustration({super.key, required this.kind});

  final EmptyIllustration kind;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(context.dimens.iconMd * 2),
      painter: _IllustrationPainter(
        kind,
        context.colors.textTertiary,
        context.dimens.borderHairline,
      ),
    ),
  );
}

class _IllustrationPainter extends CustomPainter {
  const _IllustrationPainter(this.kind, this.color, this.strokeWidth);

  final EmptyIllustration kind;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.save();
    canvas.scale(size.width / 40, size.height / 40);
    if (kind == EmptyIllustration.star) {
      final Path star = Path();
      for (int i = 0; i < 10; i++) {
        final double angle = -math.pi / 2 + i * math.pi / 5;
        final double radius = i.isEven ? 18 : 8.5;
        final double x = 20 + math.cos(angle) * radius;
        final double y = 21 + math.sin(angle) * radius;
        if (i == 0) {
          star.moveTo(x, y);
        } else {
          star.lineTo(x, y);
        }
      }
      canvas.drawPath(star..close(), paint);
    } else {
      canvas.drawCircle(const Offset(17, 17), 12, paint);
      canvas.drawLine(const Offset(25.5, 25.5), const Offset(36, 36), paint);
      if (kind == EmptyIllustration.noResults) {
        canvas.drawLine(const Offset(12, 12), const Offset(22, 22), paint);
        canvas.drawLine(const Offset(22, 12), const Offset(12, 22), paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
