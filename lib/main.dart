import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/sample_watchlist.dart';
import 'screens/home_screen.dart';
import 'state/watchlist_controller.dart';
import 'theme/theme.dart';

void main() {
  runApp(const EdencrewAssignmentApp());
}

class EdencrewAssignmentApp extends StatelessWidget {
  const EdencrewAssignmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WatchlistController>(
      create: (_) => WatchlistController(
        initialStocks: sampleWatchlist,
        initialQuotes: sampleQuotes,
      ),
      child: MaterialApp(
        title: '이든크루 평가 과제',
        theme: AppTheme.dark,
        home: const HomeScreen(searchStocks: searchSampleStocks),
      ),
    );
  }
}
