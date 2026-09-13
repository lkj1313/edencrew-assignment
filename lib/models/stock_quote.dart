enum PriceDirection { up, down, flat }

/// 숫자로 보관한 시세입니다. 쉼표나 퍼센트 기호는 화면에 표시할 때 붙입니다.
class StockQuote {
  const StockQuote({
    required this.symbol,
    required this.currentPrice,
    required this.previousClose,
    this.openPrice,
    this.highPrice,
    this.lowPrice,
    this.tradingVolume,
    this.listedStockCount,
  });

  final String symbol;
  final int currentPrice;
  final int previousClose;
  final int? openPrice;
  final int? highPrice;
  final int? lowPrice;
  final int? tradingVolume;
  final int? listedStockCount;

  int? get marketCapitalization =>
      listedStockCount == null ? null : currentPrice * listedStockCount!;

  // 유효한 전일 종가가 없으면 등락을 계산할 수 없습니다.
  int? get changeAmount =>
      previousClose > 0 ? currentPrice - previousClose : null;

  double? get changePercent {
    final int? amount = changeAmount;
    return amount == null ? null : amount / previousClose * 100;
  }

  PriceDirection? get direction {
    final int? amount = changeAmount;
    if (amount == null) return null;
    if (amount > 0) return PriceDirection.up;
    if (amount < 0) return PriceDirection.down;
    return PriceDirection.flat;
  }
}
