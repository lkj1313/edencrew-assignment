import 'package:edencrew_assignment_starter/models/stock_quote.dart';
import 'package:edencrew_assignment_starter/utils/price_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('가격과 음수 등락에 천 단위 쉼표를 표시한다', () {
    expect(formatInteger(0), '0');
    expect(formatInteger(999), '999');
    expect(formatInteger(1000), '1,000');
    expect(formatInteger(123456789), '123,456,789');
    expect(formatInteger(-9500), '-9,500');
  });

  test('상승·하락·보합을 전일 종가 기준으로 계산하고 부호를 표시한다', () {
    const StockQuote up = StockQuote(
      symbol: '000660',
      currentPrice: 412500,
      previousClose: 403000,
    );
    const StockQuote down = StockQuote(
      symbol: '005930',
      currentPrice: 179700,
      previousClose: 180100,
    );
    const StockQuote flat = StockQuote(
      symbol: '247540',
      currentPrice: 195400,
      previousClose: 195400,
    );

    expect(up.changeAmount, 9500);
    expect(up.changePercent, closeTo(2.35732, 0.00001));
    expect(up.direction, PriceDirection.up);
    expect(formatPriceChange(up), '+9,500 (+2.36%)');

    expect(down.changeAmount, -400);
    expect(down.changePercent, closeTo(-0.222099, 0.000001));
    expect(down.direction, PriceDirection.down);
    expect(formatPriceChange(down), '-400 (-0.22%)');

    expect(flat.changeAmount, 0);
    expect(flat.changePercent, 0);
    expect(flat.direction, PriceDirection.flat);
    expect(formatPriceChange(flat), '0 (0.00%)');
  });

  test('유효한 전일 종가가 없으면 등락을 보합으로 표시하지 않는다', () {
    for (final int previousClose in <int>[0, -1]) {
      final StockQuote quote = StockQuote(
        symbol: '005930',
        currentPrice: 179700,
        previousClose: previousClose,
      );

      expect(quote.changeAmount, isNull);
      expect(quote.changePercent, isNull);
      expect(quote.direction, isNull);
      expect(formatPriceChange(quote), '—');
    }
  });
}
