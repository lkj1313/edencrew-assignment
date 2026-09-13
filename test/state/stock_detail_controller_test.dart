import 'dart:async';

import 'package:edencrew_assignment_starter/models/daily_price.dart';
import 'package:edencrew_assignment_starter/state/stock_detail_controller.dart';
import 'package:edencrew_assignment_starter/state/watchlist_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/detail_repository.dart';

void main() {
  test('기간 변경 전의 늦은 응답을 무시하고 종료하면 추가 페이지 요청을 취소한다', () async {
    final DetailRepository repository = DetailRepository();
    final Map<HistoryPeriod, Completer<List<DailyPrice>>> pending =
        <HistoryPeriod, Completer<List<DailyPrice>>>{};
    final Map<HistoryPeriod, bool Function()> cancelled =
        <HistoryPeriod, bool Function()>{};
    repository.historyLoader = (period, isCancelled) {
      cancelled[period] = isCancelled!;
      return (pending[period] = Completer<List<DailyPrice>>()).future;
    };
    final WatchlistController watchlist = WatchlistController();
    addTearDown(watchlist.dispose);
    final StockDetailController controller = StockDetailController(
      stock: detailStock,
      repository: repository,
      watchlist: watchlist,
    );
    final Future<void> first = controller.loadHistory();
    controller.selectPeriod(HistoryPeriod.year);
    expect(cancelled[HistoryPeriod.month]!(), isTrue);
    expect(cancelled[HistoryPeriod.year]!(), isFalse);
    pending[HistoryPeriod.month]!.complete(historyFor(HistoryPeriod.month));
    await first;
    expect(controller.period, HistoryPeriod.year);
    expect(controller.prices, isEmpty);
    controller.dispose();
    expect(cancelled[HistoryPeriod.year]!(), isTrue);
    pending[HistoryPeriod.year]!.complete(historyFor(HistoryPeriod.year));
    await Future<void>.delayed(Duration.zero);
  });

  test('시세 오류와 일별 오류는 독립적으로 재시도하며 기존 가격을 유지한다', () async {
    final DetailRepository repository = DetailRepository()..failQuote = true;
    final WatchlistController watchlist = WatchlistController();
    addTearDown(watchlist.dispose);
    final StockDetailController controller = StockDetailController(
      stock: detailStock,
      repository: repository,
      watchlist: watchlist,
    );
    addTearDown(controller.dispose);
    await Future.wait(<Future<void>>[
      controller.refreshQuote(),
      controller.loadHistory(),
    ]);
    expect(controller.quoteError, isNotNull);
    expect(controller.historyError, isNull);
    expect(controller.prices.length, 20);
    repository.failQuote = false;
    await controller.refreshQuote();
    expect(controller.quote, detailQuote);
    repository.failQuote = true;
    await controller.refreshQuote();
    expect(controller.quote, detailQuote);
    repository.failHistory = true;
    await controller.loadHistory();
    expect(controller.historyError, isNotNull);
    repository.failHistory = false;
    await controller.loadHistory();
    expect(controller.historyError, isNull);
    expect(controller.prices.length, 20);
  });
}
