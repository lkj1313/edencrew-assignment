import 'dart:convert';

import 'package:charset/charset.dart';
import 'package:http/http.dart' as http;

import '../models/stock.dart';
import '../models/stock_quote.dart';
import 'naver_stock_dto.dart';
import 'stock_repository.dart';

class NaverStockRepository implements StockRepository {
  NaverStockRepository({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final Map<String, Stock> _metadata = <String, Stock>{};
  final Map<String, Future<Stock>> _pendingMetadata = <String, Future<Stock>>{};

  void dispose() {
    if (_ownsClient) _client.close();
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final http.Response response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', uri);
    }
    final String contentType =
        response.headers['content-type']?.toLowerCase() ?? '';
    final String body = contentType.contains('euc-kr')
        ? const EucKRCodec().decode(response.bodyBytes)
        : utf8.decode(response.bodyBytes);
    return jsonObject(jsonDecode(body));
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
}
