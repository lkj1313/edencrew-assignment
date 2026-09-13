/// 날짜는 yyyyMMdd, 숫자는 표시용 문자열이 아닌 원래 값으로 보관합니다.
class DailyPrice {
  const DailyPrice({
    required this.localDate,
    required this.closePrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.accumulatedTradingVolume,
    required this.changeAmount,
  });

  final String localDate;
  final int closePrice;
  final int openPrice;
  final int highPrice;
  final int lowPrice;
  final int accumulatedTradingVolume;
  final int? changeAmount;

  String get displayDate =>
      '${localDate.substring(4, 6)}.${localDate.substring(6)}';

  // 거래 정지 등의 0원 OHLC는 표에 남기되 캔들 축을 왜곡하지 않습니다.
  bool get hasCandle =>
      openPrice > 0 && lowPrice > 0 && highPrice > 0 && closePrice > 0;
}

enum HistoryPeriod {
  month('1개월', 20),
  threeMonths('3개월', 60),
  sixMonths('6개월', 120),
  year('1년', 245);

  const HistoryPeriod(this.label, this.tradingDays);
  final String label;
  final int tradingDays;
}
