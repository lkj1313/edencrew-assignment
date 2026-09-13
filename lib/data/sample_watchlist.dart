import '../models/stock.dart';
import '../models/stock_quote.dart';

// 화면 개발용 샘플입니다. 실제 시세가 아니며 API 연동 시 교체합니다.
const List<Stock> sampleWatchlist = <Stock>[
  Stock(symbol: '005930', name: '삼성전자', market: '코스피'),
];

const List<StockQuote> sampleQuotes = <StockQuote>[
  StockQuote(symbol: '005930', currentPrice: 179700, previousClose: 180100),
];
