import 'dart:convert';

import 'package:charset/charset.dart';
import 'package:http/http.dart' as http;

import '../models/stock.dart';
import '../models/daily_price.dart';
import '../models/stock_quote.dart';
import 'naver_stock_dto.dart';
import 'naver_daily_price_dto.dart';
import 'stock_repository.dart';

class NaverStockRepository implements StockRepository {
  NaverStockRepository({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _now = now ?? DateTime.now;

  final http.Client _client;
  final bool _ownsClient;
  final DateTime Function() _now;
  final Map<String, _DailyCache> _dailyCache = <String, _DailyCache>{};
  final Map<String, Stock> _metadata = <String, Stock>{};
  final Map<String, Future<Stock>> _pendingMetadata = <String, Future<Stock>>{};

  void dispose() {
    if (_ownsClient) _client.close();
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    return jsonObject(jsonDecode(await _getText(uri)));
  }

  Future<String> _getText(Uri uri, {bool eucKrFallback = false}) async {
    final http.Response response = await _client
        .get(uri, headers: const <String, String>{'User-Agent': 'Mozilla/5.0'})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', uri);
    }
    final String contentType =
        response.headers['content-type']?.toLowerCase() ?? '';
    return (contentType.contains('euc-kr') ||
            (eucKrFallback && !contentType.contains('utf-8')))
        ? const EucKRCodec().decode(response.bodyBytes)
        : utf8.decode(response.bodyBytes);
  }

  @override
  Future<List<Stock>> searchStocks(String query) async {
    final String keyword = query.trim();
    if (keyword.isEmpty) return const <Stock>[];
    final Map<String, dynamic> json = await _getJson(
      Uri.https('ac.stock.naver.com', '/ac', <String, String>{
        'q': keyword,
        'target': 'stock,ipo,index,marketindicator',
      }),
    );
    final Object? items = json['items'];
    if (items is! List) throw const FormatException('검색 결과 목록이 없습니다.');
    final Map<String, Stock> stocks = <String, Stock>{};
    for (final Object? item in items) {
      final SearchStockDto? dto = SearchStockDto.tryParse(item);
      if (dto == null) continue;
      final Stock stock = _metadata[dto.code] ?? dto.toModel();
      stocks.putIfAbsent(stock.id, () => stock);
    }
    return List<Stock>.unmodifiable(stocks.values);
  }

  @override
  Future<Stock> fetchStock(String symbol) async {
    _validateSymbol(symbol);
    final Stock? cached = _metadata[symbol];
    if (cached != null) return cached;
    final Future<Stock>? pending = _pendingMetadata[symbol];
    if (pending != null) return pending;
    final Future<Stock> request = _fetchMetadata(symbol);
    _pendingMetadata[symbol] = request;
    try {
      final Stock stock = await request;
      _metadata[symbol] = stock;
      return stock;
    } finally {
      _pendingMetadata.remove(symbol);
    }
  }

  Future<Stock> _fetchMetadata(String symbol) async {
    final Map<String, dynamic> json = await _getJson(
      Uri.https(
        'stock.naver.com',
        '/api/securityFe/api/fchart/domestic/stock/$symbol',
      ),
    );
    final Stock stock = StockMetadataDto.fromJson(json).toModel();
    if (stock.symbol != symbol) throw const FormatException('종목 코드가 요청과 다릅니다.');
    return stock;
  }

  @override
  Future<List<StockQuote>> fetchQuotes(List<String> symbols) async {
    final Set<String> uniqueSymbols = symbols.toSet();
    if (uniqueSymbols.isEmpty) return const <StockQuote>[];
    for (final String symbol in uniqueSymbols) {
      _validateSymbol(symbol);
    }
    final Map<String, dynamic> json = await _getJson(
      Uri.https('polling.finance.naver.com', '/api/realtime', <String, String>{
        'query': 'SERVICE_ITEM:${uniqueSymbols.join(',')}',
      }),
    );
    if (json['resultCode'] != 'success') {
      throw const FormatException('시세 조회가 실패했습니다.');
    }
    final Object? areas = jsonObject(json['result'])['areas'];
    if (areas is! List) throw const FormatException('시세 목록이 없습니다.');
    final Map<String, StockQuote> quotes = <String, StockQuote>{};
    for (final Object? area in areas) {
      final Map<String, dynamic> jsonArea = jsonObject(area);
      if (jsonArea['name'] != 'SERVICE_ITEM') continue;
      final Object? data = jsonArea['datas'];
      if (data is! List) throw const FormatException('시세 항목이 없습니다.');
      for (final Object? item in data) {
        final StockQuoteDto? dto = StockQuoteDto.tryParse(item);
        if (dto != null && uniqueSymbols.contains(dto.cd)) {
          quotes[dto.cd] = dto.toModel();
        }
      }
    }
    return List<StockQuote>.unmodifiable(quotes.values);
  }

  void _validateSymbol(String symbol) {
    if (!domesticSymbolPattern.hasMatch(symbol)) {
      throw ArgumentError.value(symbol, 'symbol', '6자리 국내 종목 코드가 필요합니다.');
    }
  }

  @override
  Future<List<DailyPrice>> fetchDailyPrices(
    String symbol,
    HistoryPeriod period, {
    bool Function()? isCancelled,
  }) async {
    _validateSymbol(symbol);
    final DateTime now = _now();
    _DailyCache? cache = _dailyCache[symbol];
    // 페이지 번호가 다음 거래일에 밀리므로 오래된 페이지와 섞지 않습니다.
    if (cache == null ||
        now.difference(cache.createdAt) >= const Duration(minutes: 5)) {
      cache = _DailyCache(now);
      _dailyCache[symbol] = cache;
    }
    final Map<String, DailyPrice> rows = <String, DailyPrice>{};
    int page = 1;
    while (rows.length < period.tradingDays) {
      if (isCancelled?.call() ?? false) return const <DailyPrice>[];
      final DailyPricePageDto result = await _dailyPage(symbol, page, cache);
      if (isCancelled?.call() ?? false) return const <DailyPrice>[];
      int added = 0;
      for (final DailyPriceDto row in result.rows) {
        if (!rows.containsKey(row.localDate)) {
          rows[row.localDate] = row.toModel();
          added++;
        }
      }
      if (page >= result.lastPage || result.rows.isEmpty) break;
      if (added == 0) throw const FormatException('일별 시세 페이지가 중복되었습니다.');
      page++;
    }
    final List<DailyPrice> sorted = rows.values.toList()
      ..sort((a, b) => b.localDate.compareTo(a.localDate));
    return List<DailyPrice>.unmodifiable(sorted.take(period.tradingDays));
  }

  Future<DailyPricePageDto> _dailyPage(
    String symbol,
    int page,
    _DailyCache cache,
  ) async {
    final DailyPricePageDto? saved = cache.pages[page];
    if (saved != null) return saved;
    final Future<DailyPricePageDto>? pending = cache.pending[page];
    if (pending != null) return pending;
    final Future<DailyPricePageDto> request = _fetchDailyPage(symbol, page);
    cache.pending[page] = request;
    try {
      final DailyPricePageDto result = await request;
      cache.pages[page] = result;
      return result;
    } finally {
      cache.pending.remove(page);
    }
  }

  Future<DailyPricePageDto> _fetchDailyPage(String symbol, int page) async {
    final String source = await _getText(
      Uri.https('finance.naver.com', '/item/sise_day.naver', <String, String>{
        'code': symbol,
        'page': '$page',
      }),
      eucKrFallback: true,
    );
    return DailyPricePageDto.fromHtml(source, page: page);
  }
}

class _DailyCache {
  _DailyCache(this.createdAt);

  final DateTime createdAt;
  final Map<int, DailyPricePageDto> pages = <int, DailyPricePageDto>{};
  final Map<int, Future<DailyPricePageDto>> pending =
      <int, Future<DailyPricePageDto>>{};
}
