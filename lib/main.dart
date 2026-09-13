import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/naver_stock_repository.dart';
import 'data/stock_repository.dart';
import 'screens/home_screen.dart';
import 'state/watchlist_controller.dart';
import 'theme/theme.dart';

void main() {
  runApp(const EdencrewAssignmentApp());
}

class EdencrewAssignmentApp extends StatelessWidget {
  const EdencrewAssignmentApp({super.key, this.repository});

  final StockRepository? repository;

  @override
  Widget build(BuildContext context) {
    return Provider<StockRepository>(
      create: (_) => repository ?? NaverStockRepository(),
      dispose: (_, value) {
        if (repository == null) (value as NaverStockRepository).dispose();
      },
      child: ChangeNotifierProvider<WatchlistController>(
        create: (context) {
          final StockRepository repository = context.read<StockRepository>();
          return WatchlistController(
            loadQuotes: repository.fetchQuotes,
            loadStock: repository.fetchStock,
          );
        },
        child: MaterialApp(
          title: '이든크루 평가 과제',
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => HomeScreen(
              searchStocks: context.read<StockRepository>().searchStocks,
            ),
          ),
        ),
      ),
    );
  }
}
