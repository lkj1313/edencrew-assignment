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

String formatSignedInteger(int? amount) {
  if (amount == null) return '—';
  return '${amount > 0 ? '+' : ''}${formatInteger(amount)}';
}

String formatVolume(int? value) {
  if (value == null) return '—';
  return value >= 1000
      ? '${formatInteger(value ~/ 1000)}천'
      : formatInteger(value);
}

String formatMarketCapitalization(int? value) {
  if (value == null) return '—';
  if (value >= 1000000000000) {
    return '${formatInteger(value ~/ 1000000000000)}조';
  }
  if (value >= 100000000) return '${formatInteger(value ~/ 100000000)}억';
  if (value >= 10000) return '${formatInteger(value ~/ 10000)}만';
  return formatInteger(value);
}
