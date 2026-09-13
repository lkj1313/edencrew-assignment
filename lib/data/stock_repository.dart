import '../models/stock.dart';
import '../models/stock_quote.dart';

abstract interface class StockRepository {
  Future<List<Stock>> searchStocks(String query);
  Future<Stock> fetchStock(String symbol);
  Future<List<StockQuote>> fetchQuotes(List<String> symbols);
}
