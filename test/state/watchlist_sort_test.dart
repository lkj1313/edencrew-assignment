import 'package:edencrew_assignment_starter/models/stock.dart';
import 'package:edencrew_assignment_starter/models/stock_quote.dart';
import 'package:edencrew_assignment_starter/models/watchlist_sort.dart';
import 'package:edencrew_assignment_starter/state/watchlist_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Stock a = Stock(symbol: '000001', name: '가기업', market: '코스피');
  const Stock b = Stock(symbol: '000002', name: '나기업', market: '코스피');
  const Stock c = Stock(symbol: '000003', name: '다기업', market: '코스피');
  const Stock d = Stock(symbol: '000004', name: '라기업', market: '코스피');

  test('기본값은 가나다순이며 같은 이름은 코드순으로 안정적으로 정렬한다', () {
    const Stock sameName = Stock(symbol: '000005', name: '가기업', market: '코스피');
    final WatchlistController controller = WatchlistController(
      initialStocks: const <Stock>[b, sameName, a],
    );
    addTearDown(controller.dispose);
    expect(controller.sort, WatchlistSort.name);
    expect(controller.stocks, const <Stock>[a, sameName, b]);
  });

  test('현재가는 높은 순서, 미수신은 마지막이며 새 시세가 오면 위치를 다시 계산한다', () {
    final WatchlistController controller = WatchlistController(
      initialStocks: const <Stock>[c, b, a],
      initialQuotes: const <StockQuote>[
        StockQuote(symbol: '000001', currentPrice: 100, previousClose: 100),
        StockQuote(symbol: '000002', currentPrice: 200, previousClose: 100),
      ],
    );
    addTearDown(controller.dispose);
    controller.setSort(WatchlistSort.currentPrice);
    expect(controller.stocks, const <Stock>[b, a, c]);
    controller.updateQuotes(const <StockQuote>[
      StockQuote(symbol: '000003', currentPrice: 300, previousClose: 100),
    ]);
    expect(controller.stocks, const <Stock>[c, b, a]);
    controller.updateQuotes(const <StockQuote>[
      StockQuote(symbol: '000003', currentPrice: 200, previousClose: 100),
    ]);
    expect(controller.stocks, const <Stock>[b, c, a]);
  });

  test('등락률은 양수·보합·음수 순이며 계산 불가능한 값은 음수보다 뒤에 둔다', () {
    final WatchlistController controller = WatchlistController(
      initialStocks: const <Stock>[a, b, c, d],
      initialQuotes: const <StockQuote>[
        StockQuote(symbol: '000001', currentPrice: 90, previousClose: 100),
        StockQuote(symbol: '000002', currentPrice: 100, previousClose: 100),
        StockQuote(symbol: '000003', currentPrice: 110, previousClose: 100),
        StockQuote(symbol: '000004', currentPrice: 10000, previousClose: 0),
      ],
    );
    addTearDown(controller.dispose);
    controller.setSort(WatchlistSort.changePercent);
    expect(controller.stocks, const <Stock>[c, b, a, d]);
    controller.updateQuotes(const <StockQuote>[
      StockQuote(symbol: '000004', currentPrice: 10050, previousClose: 10000),
    ]);
    // 등락액은 더 커도 비율은 작으므로 10% 다음에 0.5%를 표시합니다.
    expect(controller.stocks, const <Stock>[c, d, b, a]);
  });
}
