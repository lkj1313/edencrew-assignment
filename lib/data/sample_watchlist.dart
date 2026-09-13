import '../models/stock.dart';
import '../models/stock_quote.dart';

// 화면 개발용 샘플입니다. 실제 시세가 아니며 API 연동 시 교체합니다.
const List<Stock> sampleWatchlist = <Stock>[
  Stock(symbol: '005930', name: '삼성전자', market: '코스피'),
];

const List<StockQuote> sampleQuotes = <StockQuote>[
  StockQuote(symbol: '005930', currentPrice: 179700, previousClose: 180100),
];

Future<List<Stock>> searchSampleStocks(String query) async {
  const List<Stock> stocks = <Stock>[
    Stock(symbol: '005930', name: '삼성전자', market: '코스피'),
    Stock(symbol: '005935', name: '삼성전자우', market: '코스피'),
    Stock(symbol: '000660', name: 'SK하이닉스', market: '코스피'),
  ];
  final String keyword = query.toLowerCase();
  return stocks
      .where(
        (stock) =>
            stock.name.toLowerCase().contains(keyword) ||
            stock.symbol.contains(keyword),
      )
      .toList();
}
