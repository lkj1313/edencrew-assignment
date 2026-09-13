import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/models/daily_price.dart';
import 'package:edencrew_assignment_starter/models/stock.dart';
import 'package:edencrew_assignment_starter/models/stock_quote.dart';

const Stock detailStock = Stock(symbol: '005930', name: '삼성전자', market: '코스피');
const StockQuote detailQuote = StockQuote(
  symbol: '005930',
  currentPrice: 259500,
  previousClose: 269000,
  openPrice: 258000,
  highPrice: 261500,
  lowPrice: 256500,
  tradingVolume: 13938673,
  listedStockCount: 5846278608,
);

List<DailyPrice> historyFor(
  HistoryPeriod period,
) => List<DailyPrice>.generate(period.tradingDays, (index) {
  final DateTime date = DateTime.utc(
    2026,
    9,
    11,
  ).subtract(Duration(days: index));
  final String localDate =
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  return DailyPrice(
    localDate: localDate,
    closePrice: 1000 + index,
    openPrice: 1005 + index,
    highPrice: 1010 + index,
    lowPrice: 990 + index,
    accumulatedTradingVolume: 20000,
    changeAmount: index == 0 ? -10 : 10,
  );
});

class DetailRepository implements StockRepository {
  final List<HistoryPeriod> requestedPeriods = <HistoryPeriod>[];
  bool failQuote = false;
  bool failHistory = false;
  Future<List<DailyPrice>> Function(HistoryPeriod, bool Function()?)?
  historyLoader;

  @override
  Future<Stock> fetchStock(String symbol) async => detailStock;
  @override
  Future<List<Stock>> searchStocks(String query) async => <Stock>[detailStock];
  @override
  Future<List<StockQuote>> fetchQuotes(List<String> symbols) async {
    if (failQuote) throw Exception('quote failed');
    return <StockQuote>[detailQuote];
  }

  @override
  Future<List<DailyPrice>> fetchDailyPrices(
    String symbol,
    HistoryPeriod period, {
    bool Function()? isCancelled,
  }) async {
    requestedPeriods.add(period);
    if (historyLoader != null) return historyLoader!(period, isCancelled);
    if (failHistory) throw Exception('history failed');
    return historyFor(period);
  }
}
