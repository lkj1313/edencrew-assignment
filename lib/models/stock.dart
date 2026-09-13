/// 종목을 식별하는 기본 정보입니다. 가격은 StockQuote에서 관리합니다.
class Stock {
  const Stock({required this.symbol, required this.name, required this.market});

  final String symbol;
  final String name;
  final String market;

  String get id => 'domestic:$symbol';
}
