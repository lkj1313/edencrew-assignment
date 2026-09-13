import 'dart:convert';
import 'dart:io';

import 'package:edencrew_assignment_starter/data/naver_stock_repository.dart';
import 'package:edencrew_assignment_starter/models/stock.dart';
import 'package:edencrew_assignment_starter/models/stock_quote.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonResponse(Object value) => http.Response.bytes(
  utf8.encode(jsonEncode(value)),
  200,
  headers: <String, String>{'content-type': 'application/json;charset=UTF-8'},
);

void main() {
  test('실제 검색 응답을 모델로 연결하고 검색어를 URL 파라미터로 전달한다', () async {
    final NaverStockRepository repository = NaverStockRepository(
      client: MockClient((request) async {
        expect(request.url.host, 'ac.stock.naver.com');
        expect(request.url.queryParameters['q'], '삼성 E&A');
        expect(
          request.url.queryParameters['target'],
          'stock,ipo,index,marketindicator',
        );
        return http.Response.bytes(
          await File('assets/mock/search_samsung.json').readAsBytes(),
          200,
        );
      }),
    );
    final List<Stock> stocks = await repository.searchStocks(' 삼성 E&A ');
    expect(stocks.first.id, 'domestic:005930');
    expect(stocks.first.name, '삼성전자');
    expect(stocks.first.market, '코스피');
    expect(stocks.map((stock) => stock.id).toSet().length, stocks.length);
  });

  test('해외·ETF·지수·잘못된 코드·불완전 항목을 제외하고 같은 코드는 중복 제거한다', () async {
    final Map<String, dynamic> valid = <String, dynamic>{
      'code': '005930',
      'name': '삼성전자',
      'typeCode': 'KOSPI',
      'typeName': '코스피',
      'nationCode': 'KOR',
      'category': 'stock',
    };
    final NaverStockRepository repository = NaverStockRepository(
      client: MockClient(
        (_) async => jsonResponse(<String, dynamic>{
          'items': <Object?>[
            valid,
            valid,
            <String, dynamic>{...valid, 'nationCode': 'USA'},
            <String, dynamic>{...valid, 'category': 'etf'},
            <String, dynamic>{...valid, 'typeCode': 'INDEX'},
            <String, dynamic>{...valid, 'code': '5930'},
            <String, dynamic>{...valid, 'code': '00593A'},
            <String, dynamic>{...valid, 'name': null},
            <String, dynamic>{...valid, 'code': '035720', 'name': '카카오'},
            null,
          ],
        }),
      ),
    );
    expect(
      (await repository.searchStocks('삼성')).map((stock) => stock.symbol),
      <String>['005930', '035720'],
    );
  });

  test('메타데이터 중복 요청을 공유하고 후속 검색에 캐시한 이름과 시장을 적용한다', () async {
    int metadataCalls = 0;
    final NaverStockRepository repository = NaverStockRepository(
      client: MockClient((request) async {
        if (request.url.host == 'stock.naver.com') {
          metadataCalls++;
          return jsonResponse(<String, String>{
            'symbolCode': '005930',
            'stockName': '확인된 종목명',
            'stockExchangeNameKor': '코스피',
          });
        }
        return http.Response.bytes(
          await File('assets/mock/search_samsung.json').readAsBytes(),
          200,
        );
      }),
    );
    final List<Stock> stocks = await Future.wait(<Future<Stock>>[
      repository.fetchStock('005930'),
      repository.fetchStock('005930'),
    ]);
    expect(stocks.every((stock) => stock.name == '확인된 종목명'), isTrue);
    await repository.fetchStock('005930');
    expect(metadataCalls, 1);
    expect((await repository.searchStocks('삼성')).first.name, '확인된 종목명');
  });

  test('실제 메타데이터 응답을 변환하고 요청과 다른 종목 응답은 거부한다', () async {
    final NaverStockRepository repository = NaverStockRepository(
      client: MockClient(
        (_) async => http.Response.bytes(
          await File('assets/mock/metadata_005930.json').readAsBytes(),
          200,
        ),
      ),
    );
    expect((await repository.fetchStock('005930')).market, '코스피');
    await expectLater(repository.fetchStock('000660'), throwsFormatException);
  });

  test('관심 종목들을 한 요청으로 조회하고 EUC-KR 실제 응답과 시가총액을 해석한다', () async {
    int calls = 0;
    final NaverStockRepository repository = NaverStockRepository(
      client: MockClient((request) async {
        calls++;
        expect(
          request.url.queryParameters['query'],
          'SERVICE_ITEM:005930,000660',
        );
        return http.Response.bytes(
          await File(
            'assets/mock/realtime_005930_000660.euc-kr.txt',
          ).readAsBytes(),
          200,
          headers: <String, String>{
            'content-type': 'text/plain;charset=EUC-KR',
          },
        );
      }),
    );
    final List<StockQuote> quotes = await repository.fetchQuotes(<String>[
      '005930',
      '000660',
      '005930',
    ]);
    expect(calls, 1);
    expect(quotes.map((quote) => quote.symbol), <String>['005930', '000660']);
    expect(quotes.first.currentPrice, 259500);
    expect(quotes.first.changeAmount, -9500);
    expect(quotes.first.direction, PriceDirection.down);
    expect(quotes.first.openPrice, 258000);
    expect(quotes.first.tradingVolume, 13938673);
    expect(quotes.first.marketCapitalization, 259500 * 5846278608);
  });

  test('유효하지 않은 시세를 0원으로 꾸미지 않고 정상 항목만 남긴다', () async {
    final NaverStockRepository repository = NaverStockRepository(
      client: MockClient(
        (_) async => jsonResponse(<String, dynamic>{
          'resultCode': 'success',
          'result': <String, dynamic>{
            'areas': <Object>[
              <String, dynamic>{
                'name': 'SERVICE_ITEM',
                'datas': <Object>[
                  <String, dynamic>{'cd': '005930', 'nv': '100,000', 'pcv': 0},
                  <String, dynamic>{'cd': '000660', 'nv': 'N/A', 'pcv': 100},
                  <String, dynamic>{'cd': '035720', 'nv': 50000},
                ],
              },
            ],
          },
        }),
      ),
    );
    final List<StockQuote> quotes = await repository.fetchQuotes(<String>[
      '005930',
      '000660',
      '035720',
    ]);
    expect(quotes.length, 1);
    expect(quotes.single.currentPrice, 100000);
    expect(quotes.single.direction, isNull);
  });

  test('빈 검색·목록은 요청하지 않고 HTTP 오류와 잘못된 응답은 오류로 전달한다', () async {
    int calls = 0;
    final NaverStockRepository repository = NaverStockRepository(
      client: MockClient((_) async {
        calls++;
        return calls == 1
            ? http.Response('unavailable', 503)
            : jsonResponse(<String, dynamic>{'unexpected': true});
      }),
    );
    expect(await repository.searchStocks('  '), isEmpty);
    expect(await repository.fetchQuotes(<String>[]), isEmpty);
    expect(calls, 0);
    await expectLater(repository.fetchStock('../bad'), throwsArgumentError);
    expect(calls, 0);
    await expectLater(
      repository.searchStocks('삼성'),
      throwsA(isA<http.ClientException>()),
    );
    await expectLater(repository.searchStocks('삼성'), throwsFormatException);
  });
}
