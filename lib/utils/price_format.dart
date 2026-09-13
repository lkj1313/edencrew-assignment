import '../models/stock_quote.dart';

final RegExp _thousandsPattern = RegExp(r'\B(?=(\d{3})+(?!\d))');

String formatInteger(int value) =>
    value.toString().replaceAll(_thousandsPattern, ',');

String formatPriceChange(StockQuote quote) {
  final int? amount = quote.changeAmount;
  final double? percent = quote.changePercent;
  if (amount == null || percent == null) return '—';

  final String sign = amount > 0 ? '+' : '';
  return '$sign${formatInteger(amount)} ($sign${percent.toStringAsFixed(2)}%)';
}
