import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/stock.dart';
import '../models/stock_quote.dart';

/// 관심 목록을 한곳에서 관리하고, 변경을 구독하는 화면에 알립니다.
class WatchlistController extends ChangeNotifier {
  WatchlistController({
    Iterable<Stock> initialStocks = const <Stock>[],
    Iterable<StockQuote> initialQuotes = const <StockQuote>[],
    this.loadQuotes,
    this.loadStock,
  }) {
    for (final Stock stock in initialStocks) {
      _stocks[stock.id] = stock;
    }
    for (final StockQuote quote in initialQuotes) {
      _quotes[quote.symbol] = quote;
    }
    if (_stocks.isNotEmpty) _scheduleRefresh();
  }

  final Future<List<StockQuote>> Function(List<String>)? loadQuotes;
  final Future<Stock> Function(String)? loadStock;
  Timer? _refreshTimer;
  int _refreshId = 0;
  bool _disposed = false;
  bool _isRefreshing = false;
  String? _quoteError;

  bool get isRefreshing => _isRefreshing;
  String? get quoteError => _quoteError;

  final Map<String, Stock> _stocks = <String, Stock>{};
  final Map<String, StockQuote> _quotes = <String, StockQuote>{};

  // 외부에서 목록을 직접 수정해 변경 알림을 빠뜨리지 않도록 합니다.
  List<Stock> get stocks => List<Stock>.unmodifiable(_stocks.values);

  bool isFavorite(String symbol) => _stocks.containsKey('domestic:$symbol');

  StockQuote? quoteFor(String symbol) => _quotes[symbol];
  Stock? stockFor(String symbol) => _stocks['domestic:$symbol'];

  void add(Stock stock) {
    if (_stocks.containsKey(stock.id)) return;
    _stocks[stock.id] = stock;
    notifyListeners();
    _scheduleRefresh();
    unawaited(_updateMetadata(stock));
  }

  void remove(String symbol) {
    if (_stocks.remove('domestic:$symbol') == null) return;
    if (_stocks.isEmpty) {
      _refreshTimer?.cancel();
      _refreshId++;
      _isRefreshing = false;
      _quoteError = null;
    }
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

  void _scheduleRefresh() {
    if (loadQuotes == null) return;
    _refreshTimer?.cancel();
    // 연속 등록을 짧게 모아 현재 관심목록 전체를 한 번에 요청합니다.
    _refreshTimer = Timer(const Duration(milliseconds: 100), refreshQuotes);
  }

  Future<void> _updateMetadata(Stock fallback) async {
    if (loadStock == null) return;
    try {
      final Stock stock = await loadStock!(fallback.symbol);
      if (_disposed ||
          stock.symbol != fallback.symbol ||
          !isFavorite(stock.symbol)) {
        return;
      }
      _stocks[stock.id] = stock;
      notifyListeners();
    } catch (_) {
      // 기본 정보 보강에 실패하면 검색 API에서 받은 이름과 시장을 유지합니다.
    }
  }

  Future<void> refreshQuotes() async {
    _refreshTimer?.cancel();
    if (_disposed || loadQuotes == null || _stocks.isEmpty) return;
    final int requestId = ++_refreshId;
    final List<String> symbols = _stocks.values
        .map((stock) => stock.symbol)
        .toList();
    _isRefreshing = true;
    _quoteError = null;
    notifyListeners();
    try {
      final List<StockQuote> quotes = await loadQuotes!(symbols);
      if (_disposed || requestId != _refreshId) return;
      final Set<String> received = <String>{};
      for (final StockQuote quote in quotes) {
        if (symbols.contains(quote.symbol)) {
          _quotes[quote.symbol] = quote;
          received.add(quote.symbol);
        }
      }
      if (symbols.any(
        (symbol) => isFavorite(symbol) && !received.contains(symbol),
      )) {
        _quoteError = '일부 종목의 시세를 받지 못했습니다.';
      }
    } catch (_) {
      if (_disposed || requestId != _refreshId) return;
      _quoteError = '시세를 불러오지 못했습니다. 다시 시도해 주세요.';
    }
    if (_disposed || requestId != _refreshId) return;
    _isRefreshing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    super.dispose();
  }
}
