import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/daily_price.dart';
import '../theme/theme.dart';

class CandlestickChart extends StatelessWidget {
  const CandlestickChart({
    super.key,
    required this.prices,
    required this.period,
  });

  final List<DailyPrice> prices;
  final HistoryPeriod period;

  @override
  Widget build(BuildContext context) {
    final List<DailyPrice> candles =
        prices.where((price) => price.hasCandle).toList()
          ..sort((a, b) => a.localDate.compareTo(b.localDate));
    final AppDimens dimens = context.dimens;
    if (candles.isEmpty) {
      return Center(
        child: Text(
          '표시할 캔들 시세가 없습니다',
          style: TextStyle(color: context.colors.textTertiary, fontSize: 12),
        ),
      );
    }
    return Semantics(
      label:
          '${period.label} 캔들 차트, ${candles.length}거래일, ${candles.first.displayDate}부터 ${candles.last.displayDate}까지. 상세 수치는 아래 일별 시세 표에서 확인할 수 있습니다.',
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dimens.space4),
        child: CustomPaint(
          key: const ValueKey<String>('candlestick-plot'),
          size: Size.infinite,
          painter: CandlePainter(
            candles: candles,
            upColor: context.colors.chartLineUp,
            downColor: context.colors.chartLineDown,
            flatColor: context.colors.chartLineFlat,
            strokeWidth: dimens.borderHairline,
          ),
        ),
      ),
    );
  }
}

class CandlePainter extends CustomPainter {
  CandlePainter({
    required this.candles,
    required this.upColor,
    required this.downColor,
    required this.flatColor,
    required this.strokeWidth,
  });

  final List<DailyPrice> candles;
  final Color upColor;
  final Color downColor;
  final Color flatColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty || size.isEmpty) return;
    final int lowest = candles.map((price) => price.lowPrice).reduce(math.min);
    final int highest = candles
        .map((price) => price.highPrice)
        .reduce(math.max);
    final double range = math.max(
      (highest - lowest).toDouble(),
      math.max(highest * 0.01, 1),
    );
    final double center = (highest + lowest) / 2;
    final double bottom = center - range * 0.6;
    final double top = center + range * 0.6;
    double y(int price) => size.height * (top - price) / (top - bottom);
    final double step = size.width / candles.length;
    final double width = step * 0.65;
    final Paint paint = Paint()..strokeWidth = math.min(strokeWidth, width);
    for (int index = 0; index < candles.length; index++) {
      final DailyPrice candle = candles[index];
      paint.color = candle.closePrice > candle.openPrice
          ? upColor
          : candle.closePrice < candle.openPrice
          ? downColor
          : flatColor;
      final double x = step * (index + 0.5);
      canvas.drawLine(
        Offset(x, y(candle.highPrice)),
        Offset(x, y(candle.lowPrice)),
        paint,
      );
      final double open = y(candle.openPrice);
      final double close = y(candle.closePrice);
      final double height = math.max((open - close).abs(), strokeWidth);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, (open + close) / 2),
          width: width,
          height: height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CandlePainter oldDelegate) =>
      oldDelegate.candles != candles ||
      oldDelegate.upColor != upColor ||
      oldDelegate.downColor != downColor ||
      oldDelegate.flatColor != flatColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
