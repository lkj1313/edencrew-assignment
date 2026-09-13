import 'package:flutter/foundation.dart';

import '../models/stock.dart';
import '../models/stock_quote.dart';

/// 관심 목록을 한곳에서 관리하고, 변경을 구독하는 화면에 알립니다.
class WatchlistController extends ChangeNotifier {
  WatchlistController({
    Iterable<Stock> initialStocks = const <Stock>[],
    Iterable<StockQuote> initialQuotes = const <StockQuote>[],
  }) {
    for (final Stock stock in initialStocks) {
      _stocks[stock.id] = stock;
    }
    for (final StockQuote quote in initialQuotes) {
      _quotes[quote.symbol] = quote;
    }
  }

  final Map<String, Stock> _stocks = <String, Stock>{};
  final Map<String, StockQuote> _quotes = <String, StockQuote>{};

  // 외부에서 목록을 직접 수정해 변경 알림을 빠뜨리지 않도록 합니다.
  List<Stock> get stocks => List<Stock>.unmodifiable(_stocks.values);

  bool isFavorite(String symbol) => _stocks.containsKey('domestic:$symbol');

  StockQuote? quoteFor(String symbol) => _quotes[symbol];

  void add(Stock stock) {
    if (_stocks.containsKey(stock.id)) return;
    _stocks[stock.id] = stock;
    notifyListeners();
  }

  void remove(String symbol) {
    if (_stocks.remove('domestic:$symbol') == null) return;
    notifyListeners();
  }

  /// 등록 후에는 true, 해제 후에는 false를 반환합니다.
  bool toggle(Stock stock) {
    if (isFavorite(stock.symbol)) {
      remove(stock.symbol);
      return false;
    }
    add(stock);
    return true;
  }

  /// 여러 종목을 조회한 결과도 한 번의 알림으로 화면에 반영합니다.
  void updateQuotes(Iterable<StockQuote> quotes) {
    bool updated = false;
    for (final StockQuote quote in quotes) {
      _quotes[quote.symbol] = quote;
      updated = true;
    }
    if (updated) notifyListeners();
  }
}
