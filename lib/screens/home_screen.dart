import 'package:flutter/material.dart';

import '../models/stock.dart';
import '../theme/theme.dart';
import '../widgets/app_bottom_navigation.dart';
import 'search_screen.dart';
import 'watchlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.searchStocks});

  final Future<List<Stock>> Function(String query) searchStocks;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.surfaceBase,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 393),
          child: Scaffold(
            body: SafeArea(
              bottom: false,
              // 탭을 바꿔도 검색어와 결과, 스크롤 위치를 유지합니다.
              child: IndexedStack(
                index: _selectedTab,
                children: <Widget>[
                  const WatchlistScreen(),
                  SearchScreen(searchStocks: widget.searchStocks),
                ],
              ),
            ),
            bottomNavigationBar: AppBottomNavigation(
              selectedIndex: _selectedTab,
              onSelected: (index) {
                FocusManager.instance.primaryFocus?.unfocus();
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                setState(() => _selectedTab = index);
              },
            ),
          ),
        ),
      ),
    );
  }
}
