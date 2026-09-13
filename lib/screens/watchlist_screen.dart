import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/stock.dart';
import '../state/watchlist_controller.dart';
import '../theme/theme.dart';
import '../widgets/stock_quote_row.dart';

/// 관심 화면의 제목과 종목 목록을 배치합니다.
class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dimens.space4,
            vertical: dimens.space3,
          ),
          child: Text(
            '관심',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 20,
              fontWeight: AppTypography.bold,
              height: 1.6,
            ),
          ),
        ),
        Expanded(
          // 목록 영역만 공통 상태의 변경을 구독합니다.
          child: Consumer<WatchlistController>(
            builder: (context, watchlist, child) {
              final List<Stock> stocks = watchlist.stocks;
              if (stocks.isEmpty) {
                return const _EmptyWatchlist();
              }

              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: stocks.length,
                itemBuilder: (context, index) {
                  final Stock stock = stocks[index];
                  return StockQuoteRow(
                    key: ValueKey<String>(stock.id),
                    stock: stock,
                    quote: watchlist.quoteFor(stock.symbol),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyWatchlist extends StatelessWidget {
  const _EmptyWatchlist();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.star_border_rounded,
              size: dimens.iconMd * 2,
              color: colors.textTertiary,
            ),
            SizedBox(height: dimens.space4),
            Text(
              '관심 종목이 없습니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: AppTypography.medium,
                height: 1.5,
              ),
            ),
            SizedBox(height: dimens.space2),
            Text(
              '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 12,
                fontWeight: AppTypography.regular,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
