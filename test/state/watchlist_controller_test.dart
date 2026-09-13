import 'package:edencrew_assignment_starter/models/stock.dart';
import 'package:edencrew_assignment_starter/models/stock_quote.dart';
import 'package:edencrew_assignment_starter/state/watchlist_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Stock samsung = Stock(symbol: '005930', name: '삼성전자', market: '코스피');
  const Stock hynix = Stock(symbol: '000660', name: 'SK하이닉스', market: '코스피');

  test('같은 종목 코드의 중복 등록과 없는 종목 해제는 목록을 바꾸지 않는다', () {
    final WatchlistController controller = WatchlistController();
    addTearDown(controller.dispose);
    int notifications = 0;
    controller.addListener(() => notifications++);

    controller.add(samsung);
    controller.add(
      const Stock(symbol: '005930', name: '다른 검색 결과 이름', market: '코스피'),
    );
    controller.remove('000660');

    expect(controller.stocks, <Stock>[samsung]);
    expect(controller.stocks.single.id, 'domestic:005930');
    expect(notifications, 1);
  });

  test('관심 등록과 해제는 다른 관심종목에 영향을 주지 않는다', () {
    final WatchlistController controller = WatchlistController(
      initialStocks: <Stock>[samsung],
    );
    addTearDown(controller.dispose);

    expect(controller.toggle(hynix), isTrue);
    expect(controller.isFavorite(hynix.symbol), isTrue);
    expect(controller.toggle(hynix), isFalse);
    expect(controller.isFavorite(hynix.symbol), isFalse);
    expect(controller.stocks, <Stock>[samsung]);
  });

  test('외부에서는 관심 목록을 직접 수정할 수 없다', () {
    final WatchlistController controller = WatchlistController(
      initialStocks: <Stock>[samsung],
    );
    addTearDown(controller.dispose);

    expect(() => controller.stocks.add(hynix), throwsUnsupportedError);
    expect(controller.stocks, <Stock>[samsung]);
  });

  test('묶음 시세를 한 번에 알리고 일부 종목 갱신 시 나머지 시세를 유지한다', () {
    final WatchlistController controller = WatchlistController();
    addTearDown(controller.dispose);
    int notifications = 0;
    controller.addListener(() => notifications++);

    controller.updateQuotes(const <StockQuote>[
      StockQuote(symbol: '005930', currentPrice: 179700, previousClose: 180100),
      StockQuote(symbol: '000660', currentPrice: 412500, previousClose: 403000),
    ]);
    expect(notifications, 1);
    expect(controller.quoteFor('005930')?.currentPrice, 179700);
    expect(controller.quoteFor('000660')?.currentPrice, 412500);
    expect(controller.quoteFor('035720'), isNull);

    controller.updateQuotes(const <StockQuote>[
      StockQuote(symbol: '005930', currentPrice: 180200, previousClose: 180100),
    ]);
    controller.updateQuotes(const <StockQuote>[]);

    expect(notifications, 2);
    expect(controller.quoteFor('005930')?.currentPrice, 180200);
    expect(controller.quoteFor('000660')?.currentPrice, 412500);
  });
}
