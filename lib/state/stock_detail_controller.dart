import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/stock_repository.dart';
import '../models/daily_price.dart';
import '../models/stock.dart';
import '../models/stock_quote.dart';
import 'watchlist_controller.dart';

class StockDetailController extends ChangeNotifier {
  StockDetailController({
    required Stock stock,
    required this.repository,
    required this.watchlist,
  }) : _stock = watchlist.stockFor(stock.symbol) ?? stock;

  final StockRepository repository;
  final WatchlistController watchlist;
  Stock _stock;
  Stock get stock => _stock;
  StockQuote? get quote => watchlist.quoteFor(stock.symbol);

  HistoryPeriod _period = HistoryPeriod.month;
  HistoryPeriod get period => _period;
  List<DailyPrice> _prices = const <DailyPrice>[];
  List<DailyPrice> get prices => _prices;
  bool loadingQuote = false;
  bool loadingHistory = false;
  String? quoteError;
  String? historyError;
  int _historyRequest = 0;
  int _quoteRequest = 0;
  bool _disposed = false;

  void load() {
    unawaited(_loadMetadata());
    unawaited(refreshQuote());
    unawaited(loadHistory());
  }

  Future<void> _loadMetadata() async {
    try {
      final Stock updated = await repository.fetchStock(stock.symbol);
      if (_disposed || updated.symbol != stock.symbol) return;
      _stock = updated;
      watchlist.updateStock(updated);
      notifyListeners();
    } catch (_) {
      // 이름·시장은 진입할 때 전달받은 검색/관심 정보로 유지합니다.
    }
  }

  Future<void> refreshQuote() async {
    final int request = ++_quoteRequest;
    loadingQuote = true;
    quoteError = null;
    notifyListeners();
    try {
      final List<StockQuote> result = await repository.fetchQuotes(<String>[
        stock.symbol,
      ]);
      if (_disposed || request != _quoteRequest) return;
      final List<StockQuote> matching = result
          .where((quote) => quote.symbol == stock.symbol)
          .toList();
      if (matching.isEmpty) throw const FormatException('시세가 없습니다.');
      watchlist.updateQuotes(matching);
    } catch (_) {
      if (_disposed || request != _quoteRequest) return;
      quoteError = '현재 시세를 불러오지 못했습니다.';
    }
    if (_disposed || request != _quoteRequest) return;
    loadingQuote = false;
    notifyListeners();
  }

  void selectPeriod(HistoryPeriod value) {
    if (_period == value) return;
    _period = value;
    unawaited(loadHistory());
  }

  Future<void> loadHistory() async {
    final int request = ++_historyRequest;
    final HistoryPeriod requestedPeriod = _period;
    loadingHistory = true;
    historyError = null;
    _prices = const <DailyPrice>[];
    notifyListeners();
    try {
      final List<DailyPrice> result = await repository.fetchDailyPrices(
        stock.symbol,
        requestedPeriod,
        isCancelled: () => _disposed || request != _historyRequest,
      );
      if (_disposed || request != _historyRequest) return;
      _prices = List<DailyPrice>.unmodifiable(result);
    } catch (_) {
      if (_disposed || request != _historyRequest) return;
      historyError = '일별 시세를 불러오지 못했습니다.';
    }
    if (_disposed || request != _historyRequest) return;
    loadingHistory = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _historyRequest++;
    _quoteRequest++;
    super.dispose();
  }
}
