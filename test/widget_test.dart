import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:edencrew_assignment_starter/main.dart';
import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/models/stock.dart';
import 'package:edencrew_assignment_starter/models/stock_quote.dart';
import 'package:edencrew_assignment_starter/screens/watchlist_screen.dart';
import 'package:edencrew_assignment_starter/state/watchlist_controller.dart';

void main() {
  testWidgets('관심 화면이 다크 테마로 렌더링된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      EdencrewAssignmentApp(repository: _TestRepository()),
    );

    expect(find.text('관심'), findsNWidgets(2));
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('관심 등록·시세 갱신·전체 해제가 화면에 반영된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      EdencrewAssignmentApp(repository: _TestRepository()),
    );
    final WatchlistController controller = tester
        .element(find.byType(WatchlistScreen))
        .read<WatchlistController>();

    controller.add(const Stock(symbol: '005930', name: '삼성전자', market: '코스피'));
    controller.updateQuotes(const <StockQuote>[
      StockQuote(symbol: '005930', currentPrice: 179700, previousClose: 180100),
    ]);

    controller.add(
      const Stock(symbol: '000660', name: 'SK하이닉스', market: '코스피'),
    );
    await tester.pump();

    expect(find.text('삼성전자'), findsOneWidget);
    expect(find.text('SK하이닉스'), findsOneWidget);
    expect(find.text('179,700'), findsOneWidget);
    // 행의 다른 텍스트와 접근성 라벨이 합쳐져도 로딩 안내를 확인합니다.
    final Finder loadingQuote = find.bySemanticsLabel(
      RegExp('SK하이닉스 시세를 불러오는 중입니다'),
    );
    expect(loadingQuote, findsWidgets);

    controller.updateQuotes(const <StockQuote>[
      StockQuote(symbol: '000660', currentPrice: 412500, previousClose: 403000),
    ]);
    await tester.pump();

    expect(find.text('412,500'), findsOneWidget);
    expect(find.text('+9,500 (+2.36%)'), findsOneWidget);
    expect(loadingQuote, findsNothing);

    controller.remove('005930');
    await tester.pump();
    expect(find.text('삼성전자'), findsNothing);
    expect(find.text('SK하이닉스'), findsOneWidget);

    controller.remove('000660');
    await tester.pump();
    expect(find.text('SK하이닉스'), findsNothing);
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
    expect(find.text('관심'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}

class _TestRepository implements StockRepository {
  @override
  Future<List<Stock>> searchStocks(String query) async => const <Stock>[];

  @override
  Future<Stock> fetchStock(String symbol) async => Stock(
    symbol: symbol,
    name: symbol == '005930' ? '삼성전자' : 'SK하이닉스',
    market: '코스피',
  );

  @override
  Future<List<StockQuote>> fetchQuotes(List<String> symbols) async =>
      const <StockQuote>[];
}
