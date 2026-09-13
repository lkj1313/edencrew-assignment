import '../models/stock.dart';
import '../models/daily_price.dart';
import '../models/stock_quote.dart';

abstract interface class StockRepository {
  Future<List<Stock>> searchStocks(String query);
  Future<Stock> fetchStock(String symbol);
  Future<List<StockQuote>> fetchQuotes(List<String> symbols);
  Future<List<DailyPrice>> fetchDailyPrices(
    String symbol,
    HistoryPeriod period, {
    bool Function()? isCancelled,
  });
}
