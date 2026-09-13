import 'package:edencrew_assignment_starter/models/stock.dart';
import 'package:edencrew_assignment_starter/models/stock_quote.dart';
import 'package:edencrew_assignment_starter/models/watchlist_sort.dart';
import 'package:edencrew_assignment_starter/screens/home_screen.dart';
import 'package:edencrew_assignment_starter/state/watchlist_controller.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:edencrew_assignment_starter/widgets/stock_quote_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<void> pumpWatchlist(
  WidgetTester tester,
  WatchlistController controller,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<WatchlistController>.value(
      value: controller,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: HomeScreen(searchStocks: (_) async => const <Stock>[]),
      ),
    ),
  );
}

List<String> visibleSymbols(WidgetTester tester) {
  // 재사용된 위젯의 탐색 순서가 아닌, 실제 화면의 위→아래 순서를 검증합니다.
  final List<StockQuoteRow> rows = tester
      .widgetList<StockQuoteRow>(find.byType(StockQuoteRow))
      .toList();
  rows.sort(
    (a, b) => tester
        .getTopLeft(find.byKey(a.key!))
        .dy
        .compareTo(tester.getTopLeft(find.byKey(b.key!)).dy),
  );
  return rows.map((row) => row.stock.symbol).toList();
}

void main() {
  testWidgets('정렬 선택은 칩·체크·목록에 반영되고 새로고침 후에도 정렬 기준을 유지한다', (tester) async {
    int calls = 0;
    final List<List<String>> requestedSymbols = <List<String>>[];
    final WatchlistController controller = WatchlistController(
      initialStocks: const <Stock>[
        Stock(symbol: '000001', name: '가기업', market: '코스피'),
        Stock(symbol: '000002', name: '나기업', market: '코스피'),
      ],
      loadQuotes: (symbols) async {
        calls++;
        requestedSymbols.add(List<String>.of(symbols));
        return <StockQuote>[
          StockQuote(
            symbol: '000001',
            currentPrice: calls == 1 ? 100 : 300,
            previousClose: 100,
          ),
          const StockQuote(
            symbol: '000002',
            currentPrice: 200,
            previousClose: 100,
          ),
        ];
      },
    );
    addTearDown(controller.dispose);
    await pumpWatchlist(tester, controller);
    await tester.pump(const Duration(milliseconds: 101));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(requestedSymbols.single, <String>['000001', '000002']);
    expect(controller.quoteError, isNull);
    expect(controller.quoteFor('000001')?.currentPrice, 100);
    expect(controller.quoteFor('000002')?.currentPrice, 200);
    expect(visibleSymbols(tester), <String>['000001', '000002']);

    await tester.tap(find.byKey(const ValueKey<String>('watchlist-sort')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<WatchlistSort>(WatchlistSort.name)),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<WatchlistSort>(WatchlistSort.currentPrice)),
    );
    await tester.pumpAndSettle();
    expect(find.text('정렬'), findsNothing);
    expect(controller.sort, WatchlistSort.currentPrice);
    expect(calls, 1);
    expect(controller.stocks.map((stock) => stock.symbol), <String>[
      '000002',
      '000001',
    ]);
    expect(find.text('현재가순'), findsOneWidget);
    expect(visibleSymbols(tester), <String>['000002', '000001']);

    await tester.tap(find.byTooltip('시세 새로고침'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(visibleSymbols(tester), <String>['000001', '000002']);
    expect(controller.sort, WatchlistSort.currentPrice);

    await tester.tap(find.byKey(const ValueKey<String>('tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('tab-0')));
    await tester.pumpAndSettle();
    expect(find.text('현재가순'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('watchlist-sort')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<WatchlistSort>(WatchlistSort.changePercent)),
    );
    await tester.pumpAndSettle();
    expect(find.text('등락률순'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('빈 목록과 좁은 화면에서도 헤더와 정렬 선택창이 유지된다', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final WatchlistController controller = WatchlistController();
    addTearDown(controller.dispose);
    await pumpWatchlist(tester, controller);
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
    expect(find.byTooltip('시세 새로고침'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('watchlist-sort')));
    await tester.pumpAndSettle();
    expect(find.text('정렬'), findsOneWidget);
    expect(find.text('현재가순'), findsOneWidget);
    expect(find.text('등락률순'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(
      find.byKey(const ValueKey<WatchlistSort>(WatchlistSort.name)),
    );
    await tester.pumpAndSettle();
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
  });
}
