import 'dart:async';

import 'package:edencrew_assignment_starter/models/stock.dart';
import 'package:edencrew_assignment_starter/models/stock_quote.dart';
import 'package:edencrew_assignment_starter/state/watchlist_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const Stock samsung = Stock(symbol: '005930', name: '삼성전자', market: '코스피');
const Stock hynix = Stock(symbol: '000660', name: 'SK하이닉스', market: '코스피');
const StockQuote quote = StockQuote(
  symbol: '005930',
  currentPrice: 100,
  previousClose: 90,
);

void main() {
  test('연속 등록한 종목은 전체 목록을 한 요청으로 조회한다', () async {
    final List<List<String>> requests = <List<String>>[];
    final WatchlistController controller = WatchlistController(
      loadQuotes: (symbols) async {
        requests.add(symbols);
        return const <StockQuote>[
          quote,
          StockQuote(symbol: '000660', currentPrice: 200, previousClose: 210),
        ];
      },
    );
    addTearDown(controller.dispose);
    controller.add(samsung);
    controller.add(hynix);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(requests, <List<String>>[
      <String>['005930', '000660'],
    ]);
    expect(controller.quoteFor('005930')?.currentPrice, 100);
    expect(controller.quoteError, isNull);
  });

  test('갱신 실패는 기존 가격을 유지하고 재시도 성공 시 오류를 해제한다', () async {
    int calls = 0;
    final WatchlistController controller = WatchlistController(
      initialStocks: const <Stock>[samsung],
      initialQuotes: const <StockQuote>[quote],
      loadQuotes: (_) async {
        if (++calls == 1) throw Exception('offline');
        return const <StockQuote>[
          StockQuote(symbol: '005930', currentPrice: 110, previousClose: 90),
        ];
      },
    );
    addTearDown(controller.dispose);
    await controller.refreshQuotes();
    expect(controller.quoteFor('005930')?.currentPrice, 100);
    expect(controller.quoteError, isNotNull);
    expect(controller.isRefreshing, isFalse);
    await controller.refreshQuotes();
    expect(controller.quoteFor('005930')?.currentPrice, 110);
    expect(controller.quoteError, isNull);
  });

  test('이전 갱신 응답과 전체 해제 후 도착한 시세는 무시한다', () async {
    final List<Completer<List<StockQuote>>> requests =
        <Completer<List<StockQuote>>>[];
    final WatchlistController controller = WatchlistController(
      initialStocks: const <Stock>[samsung],
      loadQuotes: (_) {
        final Completer<List<StockQuote>> response =
            Completer<List<StockQuote>>();
        requests.add(response);
        return response.future;
      },
    );
    addTearDown(controller.dispose);
    final Future<void> first = controller.refreshQuotes();
    final Future<void> second = controller.refreshQuotes();
    requests[1].complete(const <StockQuote>[quote]);
    await second;
    requests[0].complete(const <StockQuote>[
      StockQuote(symbol: '005930', currentPrice: 1, previousClose: 90),
    ]);
    await first;
    expect(controller.quoteFor('005930')?.currentPrice, 100);
    final Future<void> third = controller.refreshQuotes();
    controller.remove('005930');
    requests[2].complete(const <StockQuote>[
      StockQuote(symbol: '005930', currentPrice: 2, previousClose: 90),
    ]);
    await third;
    expect(controller.stocks, isEmpty);
    expect(controller.isRefreshing, isFalse);
    expect(controller.quoteFor('005930')?.currentPrice, 100);
  });

  test('기본 정보 보강은 화면에 반영되며 해제한 종목을 되살리지 않는다', () async {
    final Completer<Stock> response = Completer<Stock>();
    final WatchlistController controller = WatchlistController(
      loadStock: (_) => response.future,
    );
    addTearDown(controller.dispose);
    controller.add(samsung);
    response.complete(
      const Stock(symbol: '005930', name: '확인된 이름', market: '코스피'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.stockFor('005930')?.name, '확인된 이름');

    final Completer<Stock> removedResponse = Completer<Stock>();
    final WatchlistController removed = WatchlistController(
      loadStock: (_) => removedResponse.future,
    );
    addTearDown(removed.dispose);
    removed.add(samsung);
    removed.remove('005930');
    removedResponse.complete(samsung);
    await Future<void>.delayed(Duration.zero);
    expect(removed.stocks, isEmpty);
  });
}
