import 'dart:async';
import 'dart:io';

import 'package:charset/charset.dart';
import 'package:edencrew_assignment_starter/data/naver_daily_price_dto.dart';
import 'package:edencrew_assignment_starter/data/naver_stock_repository.dart';
import 'package:edencrew_assignment_starter/models/daily_price.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String pageHtml(int page, {int lastPage = 30}) {
  final StringBuffer result = StringBuffer(
    '<table class="type2"><tr><th>날짜</th></tr><tr><td colspan="7"></td></tr>',
  );
  for (int index = 0; index < 10; index++) {
    final DateTime date = DateTime.utc(
      2026,
      9,
      11,
    ).subtract(Duration(days: (page - 1) * 10 + index));
    final String label =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    result.write(
      '<tr><td>$label</td><td>1,000</td><td><em class="bu_pup"><span class="blind">상승</span></em><span class="tah">10</span></td><td>990</td><td>1,100</td><td>900</td><td>5,000</td></tr>',
    );
  }
  result.write(
    '</table><table class="Nnavi"><tr><td class="pgRR"><a href="?code=005930&amp;page=$lastPage">맨뒤</a></td></tr></table>',
  );
  return result.toString();
}

http.Response pageResponse(int page, {int lastPage = 30}) =>
    http.Response.bytes(
      const EucKRCodec().encode(pageHtml(page, lastPage: lastPage)),
      200,
      headers: <String, String>{'content-type': 'text/html;charset=EUC-KR'},
    );

void main() {
  test('실제 HTML에서 날짜·OHLC·거래량·등락 방향과 마지막 페이지를 읽는다', () async {
    final String html = const EucKRCodec().decode(
      await File('assets/mock/daily_005930_page1.euc-kr.html').readAsBytes(),
    );
    final DailyPricePageDto page = DailyPricePageDto.fromHtml(html, page: 1);
    expect(page.lastPage, 756);
    expect(page.rows.length, 10);
    final DailyPrice first = page.rows.first.toModel();
    expect(first.localDate, '20260911');
    expect(first.displayDate, '09.11');
    expect(first.closePrice, 259500);
    expect(first.openPrice, 258000);
    expect(first.highPrice, 261500);
    expect(first.lowPrice, 256500);
    expect(first.accumulatedTradingVolume, 13938673);
    expect(first.changeAmount, -9500);
    expect(page.rows[2].changeAmount, 0);
    expect(page.rows[4].changeAmount, 14500);
  });

  test('꾸밈 행을 제외하며 잘못된 날짜·숫자·표와 알 수 없는 등락을 처리한다', () {
    expect(
      () => DailyPricePageDto.fromHtml('<html>접근 제한</html>', page: 1),
      throwsFormatException,
    );
    expect(
      () => DailyPricePageDto.fromHtml(
        pageHtml(1).replaceFirst('2026.09.11', '2026.02.30'),
        page: 1,
      ),
      throwsFormatException,
    );
    expect(
      () => DailyPricePageDto.fromHtml(
        pageHtml(1).replaceFirst('<td>1,000</td>', '<td>N/A</td>'),
        page: 1,
      ),
      throwsFormatException,
    );
    final DailyPricePageDto unknown = DailyPricePageDto.fromHtml(
      pageHtml(
        1,
      ).replaceAll('<em class="bu_pup"><span class="blind">상승</span></em>', ''),
      page: 1,
    );
    expect(unknown.rows.first.changeAmount, isNull);
  });

  test('1·3·6개월·1년은 필요한 페이지만 추가하고 이미 받은 페이지를 재사용한다', () async {
    final List<int> pages = <int>[];
    final NaverStockRepository repository = NaverStockRepository(
      client: MockClient((request) async {
        expect(request.url.host, 'finance.naver.com');
        expect(request.url.path, '/item/sise_day.naver');
        expect(request.url.queryParameters['code'], '005930');
        final int page = int.parse(request.url.queryParameters['page']!);
        pages.add(page);
        return pageResponse(page);
      }),
    );
    for (final HistoryPeriod period in HistoryPeriod.values) {
      final List<DailyPrice> result = await repository.fetchDailyPrices(
        '005930',
        period,
      );
      expect(result.length, period.tradingDays);
      expect(result.first.localDate, '20260911');
      expect(
        pages,
        List<int>.generate((period.tradingDays / 10).ceil(), (i) => i + 1),
      );
    }
    await repository.fetchDailyPrices('005930', HistoryPeriod.month);
    expect(pages.length, 25);
  });

  test('lastPage를 넘지 않고 캐시가 만료되면 페이지를 처음부터 다시 받는다', () async {
    DateTime now = DateTime.utc(2026, 9, 13);
    final List<int> pages = <int>[];
    final NaverStockRepository repository = NaverStockRepository(
      now: () => now,
      client: MockClient((request) async {
        final int page = int.parse(request.url.queryParameters['page']!);
        pages.add(page);
        return pageResponse(page, lastPage: 2);
      }),
    );
    expect(
      (await repository.fetchDailyPrices('005930', HistoryPeriod.year)).length,
      20,
    );
    expect(pages, <int>[1, 2]);
    now = now.add(const Duration(minutes: 6));
    await repository.fetchDailyPrices('005930', HistoryPeriod.month);
    expect(pages, <int>[1, 2, 1, 2]);
  });

  test('진행 중인 페이지는 공유하고 취소된 기간의 뒤 페이지는 요청하지 않는다', () async {
    final Completer<http.Response> first = Completer<http.Response>();
    final List<int> pages = <int>[];
    final NaverStockRepository repository = NaverStockRepository(
      client: MockClient((request) {
        final int page = int.parse(request.url.queryParameters['page']!);
        pages.add(page);
        return page == 1
            ? first.future
            : Future<http.Response>.value(pageResponse(page));
      }),
    );
    bool cancelled = false;
    final Future<List<DailyPrice>> year = repository.fetchDailyPrices(
      '005930',
      HistoryPeriod.year,
      isCancelled: () => cancelled,
    );
    final Future<List<DailyPrice>> month = repository.fetchDailyPrices(
      '005930',
      HistoryPeriod.month,
    );
    cancelled = true;
    first.complete(pageResponse(1));
    expect(await year, isEmpty);
    expect((await month).length, 20);
    expect(pages, <int>[1, 2]);
  });

  test('중간 페이지 오류는 재시도 가능하며 성공했던 앞 페이지는 다시 요청하지 않는다', () async {
    final List<int> pages = <int>[];
    bool fail = true;
    final NaverStockRepository repository = NaverStockRepository(
      client: MockClient((request) async {
        final int page = int.parse(request.url.queryParameters['page']!);
        pages.add(page);
        if (page == 2 && fail) return http.Response('unavailable', 503);
        return pageResponse(page);
      }),
    );
    await expectLater(
      repository.fetchDailyPrices('005930', HistoryPeriod.month),
      throwsA(isA<http.ClientException>()),
    );
    fail = false;
    expect(
      (await repository.fetchDailyPrices('005930', HistoryPeriod.month)).length,
      20,
    );
    expect(pages, <int>[1, 2, 2]);
  });

  test('페이지 링크가 없는 신규 종목과 빈 시세를 처리하며 중복 페이지 반복은 거부한다', () async {
    final String singlePage = pageHtml(1).split('<table class="Nnavi">').first;
    expect(DailyPricePageDto.fromHtml(singlePage, page: 1).lastPage, 1);
    expect(
      DailyPricePageDto.fromHtml(
        '<table class="type2"><tr><td colspan="7"></td></tr></table>',
        page: 1,
      ).rows,
      isEmpty,
    );
    final NaverStockRepository repository = NaverStockRepository(
      client: MockClient((_) async => pageResponse(1)),
    );
    await expectLater(
      repository.fetchDailyPrices('005930', HistoryPeriod.month),
      throwsFormatException,
    );
    await expectLater(
      repository.fetchDailyPrices('../invalid', HistoryPeriod.year),
      throwsArgumentError,
    );
  });
}
