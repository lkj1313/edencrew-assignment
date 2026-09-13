import '../models/stock.dart';
import '../models/stock_quote.dart';

final RegExp domesticSymbolPattern = RegExp(r'^\d{6}$');

Map<String, dynamic> jsonObject(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('JSON 객체가 필요합니다.');
  }
  return value;
}

String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

int? _integer(Object? value) {
  final num? number = value is num
      ? value
      : value is String
      ? num.tryParse(value.replaceAll(',', ''))
      : null;
  if (number == null ||
      !number.isFinite ||
      number < 0 ||
      number != number.roundToDouble()) {
    return null;
  }
  return number.toInt();
}

class SearchStockDto {
  const SearchStockDto(this.code, this.name, this.market);

  final String code;
  final String name;
  final String market;

  static SearchStockDto? tryParse(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final String? code = _text(value['code']);
    final String? name = _text(value['name']);
    final String? market = _text(value['typeName']);
    if (value['nationCode'] != 'KOR' ||
        value['category'] != 'stock' ||
        !const <String>{
          'KOSPI',
          'KOSDAQ',
          'KONEX',
        }.contains(value['typeCode']) ||
        code == null ||
        !domesticSymbolPattern.hasMatch(code) ||
        name == null ||
        market == null) {
      return null;
    }
    return SearchStockDto(code, name, market);
  }

  Stock toModel() => Stock(symbol: code, name: name, market: market);
}

class StockMetadataDto {
  const StockMetadataDto(this.symbolCode, this.stockName, this.exchangeName);

  final String symbolCode;
  final String stockName;
  final String exchangeName;

  factory StockMetadataDto.fromJson(Object? value) {
    final Map<String, dynamic> json = jsonObject(value);
    final String? symbol = _text(json['symbolCode']);
    final String? name = _text(json['stockName']);
    final String? market = _text(json['stockExchangeNameKor']);
    if (symbol == null ||
        !domesticSymbolPattern.hasMatch(symbol) ||
        name == null ||
        market == null) {
      throw const FormatException('종목 기본 정보가 올바르지 않습니다.');
    }
    return StockMetadataDto(symbol, name, market);
  }

  Stock toModel() =>
      Stock(symbol: symbolCode, name: stockName, market: exchangeName);
}

class StockQuoteDto {
  const StockQuoteDto({
    required this.cd,
    required this.nv,
    required this.pcv,
    this.ov,
    this.hv,
    this.lv,
    this.aq,
    this.countOfListedStock,
  });

  final String cd;
  final int nv;
  final int pcv;
  final int? ov;
  final int? hv;
  final int? lv;
  final int? aq;
  final int? countOfListedStock;

  static StockQuoteDto? tryParse(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final String? symbol = _text(value['cd']);
    final int? current = _integer(value['nv']);
    final int? previous = _integer(value['pcv']);
    if (symbol == null ||
        !domesticSymbolPattern.hasMatch(symbol) ||
        current == null ||
        previous == null) {
      return null;
    }
    return StockQuoteDto(
      cd: symbol,
      nv: current,
      pcv: previous,
      ov: _integer(value['ov']),
      hv: _integer(value['hv']),
      lv: _integer(value['lv']),
      aq: _integer(value['aq']),
      countOfListedStock: _integer(value['countOfListedStock']),
    );
  }

  StockQuote toModel() => StockQuote(
    symbol: cd,
    currentPrice: nv,
    previousClose: pcv,
    openPrice: ov,
    highPrice: hv,
    lowPrice: lv,
    tradingVolume: aq,
    listedStockCount: countOfListedStock,
  );
}
