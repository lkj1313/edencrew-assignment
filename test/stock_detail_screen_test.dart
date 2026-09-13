import 'package:edencrew_assignment_starter/main.dart';
import 'package:edencrew_assignment_starter/models/daily_price.dart';
import 'package:edencrew_assignment_starter/screens/stock_detail_screen.dart';
import 'package:edencrew_assignment_starter/state/stock_detail_controller.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:edencrew_assignment_starter/utils/price_format.dart';
import 'package:edencrew_assignment_starter/widgets/candlestick_chart.dart';
import 'package:edencrew_assignment_starter/widgets/search_result_row.dart';
import 'package:edencrew_assignment_starter/widgets/stock_quote_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/detail_repository.dart';

Future<void> openDetail(
  WidgetTester tester,
  DetailRepository repository,
) async {
  await tester.pumpWidget(EdencrewAssignmentApp(repository: repository));
  await tester.tap(find.byKey(const ValueKey<String>('tab-1')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey<String>('stock-search-input')),
    '삼성',
  );
  await tester.pump(const Duration(milliseconds: 301));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(SearchResultRow));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('검색→상세 등록→검색·관심 반영→상세 해제→빈 관심목록으로 동기화한다', (tester) async {
    await openDetail(tester, DetailRepository());
    expect(find.byType(StockDetailScreen), findsOneWidget);
    expect(find.text('259,500'), findsOneWidget);
    expect(find.text('▼ 9,500 (-3.53%)'), findsOneWidget);
    expect(find.text('13,938천'), findsOneWidget);
    expect(find.text('1,517조'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('detail-favorite')));
    await tester.pumpAndSettle();
    expect(find.text('관심이 등록되었습니다'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('detail-back')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SearchResultRow>(find.byType(SearchResultRow)).isFavorite,
      isTrue,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '삼성',
    );
    await tester.tap(find.byKey(const ValueKey<String>('tab-0')));
    await tester.pumpAndSettle();
    expect(find.text('삼성전자'), findsOneWidget);
    await tester.tap(find.byType(StockQuoteRow));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('detail-favorite')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('detail-back')));
    await tester.pumpAndSettle();
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('모든 기간 탭이 같은 기간의 차트·표를 표시하고 좁은 화면에서 마지막 행까지 스크롤된다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final DetailRepository repository = DetailRepository();
    await openDetail(tester, repository);
    for (final HistoryPeriod period in HistoryPeriod.values) {
      await tester.tap(find.byKey(ValueKey<HistoryPeriod>(period)));
      await tester.pumpAndSettle();
      final CandlestickChart chart = tester.widget<CandlestickChart>(
        find.byType(CandlestickChart),
      );
      final StockDetailController controller = tester
          .element(find.byType(CandlestickChart))
          .read<StockDetailController>();
      expect(chart.period, period);
      expect(chart.prices.length, period.tradingDays);
      expect(controller.prices, chart.prices);
    }
    expect(repository.requestedPeriods, HistoryPeriod.values);
    final String lastDate = historyFor(HistoryPeriod.year).last.localDate;
    await tester.scrollUntilVisible(
      find.byKey(ValueKey<String>('daily-$lastDate')),
      500,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey<String>('detail-scroll')),
        matching: find.byType(Scrollable),
      ),
      maxScrolls: 30,
    );
    expect(find.byKey(ValueKey<String>('daily-$lastDate')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('현재 시세와 차트 오류를 개별 재시도하고 성공 결과로 돌아온다', (tester) async {
    final DetailRepository repository = DetailRepository()
      ..failQuote = true
      ..failHistory = true;
    await openDetail(tester, repository);
    expect(find.text('현재 시세를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('일별 시세를 불러오지 못했습니다.'), findsOneWidget);
    repository.failQuote = false;
    await tester.tap(find.byKey(const ValueKey<String>('retry-detail-quote')));
    await tester.pumpAndSettle();
    expect(find.text('259,500'), findsOneWidget);
    expect(find.text('일별 시세를 불러오지 못했습니다.'), findsOneWidget);
    repository.failHistory = false;
    await tester.tap(
      find.byKey(const ValueKey<String>('retry-detail-history')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CandlestickChart), findsOneWidget);
    expect(find.text('일별 시세를 불러오지 못했습니다.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('보합 캔들 하나와 거래 정지·빈 시세도 차트 오류 없이 처리한다', (tester) async {
    const DailyPrice flat = DailyPrice(
      localDate: '20260911',
      closePrice: 100,
      openPrice: 100,
      highPrice: 100,
      lowPrice: 100,
      accumulatedTradingVolume: 0,
      changeAmount: 0,
    );
    const DailyPrice halted = DailyPrice(
      localDate: '20260910',
      closePrice: 100,
      openPrice: 0,
      highPrice: 0,
      lowPrice: 0,
      accumulatedTradingVolume: 0,
      changeAmount: 0,
    );
    for (final List<DailyPrice> prices in <List<DailyPrice>>[
      <DailyPrice>[flat, halted],
      <DailyPrice>[halted],
      <DailyPrice>[],
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 216,
              child: CandlestickChart(
                prices: prices,
                period: HistoryPeriod.month,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      if (prices.length == 2) {
        final CustomPaint plot = tester.widget<CustomPaint>(
          find.byKey(const ValueKey<String>('candlestick-plot')),
        );
        expect((plot.painter! as CandlePainter).candles, <DailyPrice>[flat]);
      } else {
        expect(find.text('표시할 캔들 시세가 없습니다'), findsOneWidget);
      }
    }
  });

  test('거래량·시가총액 축약 및 일별 등락 부호를 표시한다', () {
    expect(formatVolume(29113999), '29,113천');
    expect(formatVolume(999), '999');
    expect(formatMarketCapitalization(1063999999999999), '1,063조');
    expect(formatMarketCapitalization(350000000), '3억');
    expect(formatMarketCapitalization(null), '—');
    expect(formatSignedInteger(-400), '-400');
    expect(formatSignedInteger(1200), '+1,200');
    expect(formatSignedInteger(0), '0');
    expect(formatSignedInteger(null), '—');
  });
}
