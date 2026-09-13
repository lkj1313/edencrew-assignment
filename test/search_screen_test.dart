import 'dart:async';

import 'package:edencrew_assignment_starter/models/stock.dart';
import 'package:edencrew_assignment_starter/screens/home_screen.dart';
import 'package:edencrew_assignment_starter/state/watchlist_controller.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:edencrew_assignment_starter/widgets/search_result_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const Stock samsung = Stock(symbol: '005930', name: '삼성전자', market: '코스피');
const Stock preferred = Stock(symbol: '005935', name: '삼성전자우', market: '코스피');
const Stock hynix = Stock(symbol: '000660', name: 'SK하이닉스', market: '코스피');

Future<WatchlistController> pumpSearch(
  WidgetTester tester,
  Future<List<Stock>> Function(String) search,
) async {
  final WatchlistController controller = WatchlistController(
    initialStocks: const <Stock>[samsung],
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<WatchlistController>.value(
      value: controller,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: HomeScreen(searchStocks: search),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey<String>('tab-1')));
  await tester.pumpAndSettle();
  return controller;
}

Future<void> enterSearch(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump(const Duration(milliseconds: 301));
  await tester.pump();
}

void main() {
  testWidgets('별 버튼과 토스트가 동작하고 탭 이동 후에도 검색과 관심 상태가 유지된다', (tester) async {
    final WatchlistController controller = await pumpSearch(
      tester,
      (_) async => const <Stock>[samsung, preferred],
    );
    expect(find.text('종목을 검색해 보세요'), findsOneWidget);
    await enterSearch(tester, '삼성');
    expect(find.byTooltip('삼성전자 관심 해제'), findsOneWidget);

    final Text name = tester.widget<Text>(
      find
          .descendant(
            of: find.byType(SearchResultRow).first,
            matching: find.byType(Text),
          )
          .first,
    );
    final TextSpan highlight =
        (name.textSpan! as TextSpan).children!.first as TextSpan;
    expect(highlight.text, '삼성');
    expect(highlight.style!.color, const AppColors.dark().searchHighlight);

    await tester.tap(find.byTooltip('삼성전자우 관심 등록'));
    await tester.pumpAndSettle();
    expect(controller.isFavorite('005935'), isTrue);
    expect(find.text('관심이 등록되었습니다'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('tab-0')));
    await tester.pumpAndSettle();
    expect(find.text('삼성전자우'), findsOneWidget);
    expect(find.text('관심이 등록되었습니다'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('tab-1')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '삼성',
    );
    await tester.tap(find.byTooltip('삼성전자우 관심 해제'));
    await tester.pumpAndSettle();
    expect(controller.isFavorite('005935'), isFalse);
    expect(find.text('관심이 해제되었습니다'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('관심이 해제되었습니다'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('이전 검색 응답이 늦게 와도 최신 검색 결과를 덮어쓰지 않는다', (tester) async {
    final Map<String, Completer<List<Stock>>> requests =
        <String, Completer<List<Stock>>>{};
    await pumpSearch(tester, (query) {
      final Completer<List<Stock>> result = Completer<List<Stock>>();
      requests[query] = result;
      return result.future;
    });
    await enterSearch(tester, '삼성');
    await enterSearch(tester, 'SK');
    requests['SK']!.complete(const <Stock>[hynix]);
    await tester.pump();
    requests['삼성']!.complete(const <Stock>[samsung]);
    await tester.pump();
    expect(find.text('SK하이닉스', findRichText: true), findsOneWidget);
    expect(find.text('삼성전자', findRichText: true), findsNothing);
  });

  testWidgets('빠른 입력은 한 번 조회하고 지운 뒤 도착한 응답은 무시한다', (tester) async {
    int calls = 0;
    final Completer<List<Stock>> response = Completer<List<Stock>>();
    await pumpSearch(tester, (_) {
      calls++;
      return response.future;
    });
    await tester.enterText(find.byType(TextField), '삼');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), '삼성');
    await tester.pump(const Duration(milliseconds: 299));
    expect(calls, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls, 1);
    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pump();
    response.complete(const <Stock>[samsung]);
    await tester.pump();
    expect(find.text('종목을 검색해 보세요'), findsOneWidget);
    expect(find.byType(SearchResultRow), findsNothing);
  });

  testWidgets('검색 실패는 재시도할 수 있고 긴 검색어도 빈 상태에서 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int calls = 0;
    await pumpSearch(tester, (_) async {
      if (++calls == 1) throw Exception('network');
      return const <Stock>[];
    });
    final String query = '없는종목' * 30;
    await enterSearch(tester, query);
    expect(find.text('검색 결과를 불러오지 못했습니다'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text("'$query'와 일치하는 검색 결과를 찾지 못했습니다."), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pump();
    expect(find.text('종목을 검색해 보세요'), findsOneWidget);
  });
}
