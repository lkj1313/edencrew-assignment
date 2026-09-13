import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/stock.dart';
import '../state/watchlist_controller.dart';
import '../theme/theme.dart';
import '../widgets/stock_quote_row.dart';
import '../widgets/watchlist_sort_button.dart';
import '../widgets/empty_state_message.dart';
import 'stock_detail_screen.dart';

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
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '관심',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 19,
                    fontWeight: AppTypography.bold,
                    height: 22 / 19,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const WatchlistSortButton(),
              SizedBox(width: dimens.space2),
              Consumer<WatchlistController>(
                builder: (context, watchlist, child) {
                  return IconButton(
                    tooltip: '시세 새로고침',
                    constraints: BoxConstraints.tightFor(
                      width: dimens.iconMd + dimens.space2,
                      height: dimens.iconMd + dimens.space2,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed:
                        watchlist.stocks.isEmpty || watchlist.isRefreshing
                        ? null
                        : watchlist.refreshQuotes,
                    icon: watchlist.isRefreshing
                        ? SizedBox.square(
                            dimension: dimens.iconSm,
                            child: CircularProgressIndicator(
                              strokeWidth: dimens.borderHairline,
                              color: context.colors.textSecondary,
                              semanticsLabel: '시세 갱신 중',
                            ),
                          )
                        : Icon(
                            Icons.refresh_rounded,
                            size: dimens.iconMd,
                            color: context.colors.textTertiary,
                          ),
                  );
                },
              ),
            ],
          ),
        ),
        Consumer<WatchlistController>(
          builder: (context, watchlist, child) {
            if (watchlist.quoteError == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: dimens.space4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      watchlist.quoteError!,
                      style: TextStyle(
                        color: context.colors.feedbackWarning,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: watchlist.isRefreshing
                        ? null
                        : watchlist.refreshQuotes,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          },
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
                    onTap: () => openStockDetail(context, stock),
                    quote: watchlist.quoteFor(stock.symbol),
                    quoteUnavailable:
                        watchlist.quoteError != null && !watchlist.isRefreshing,
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
    return const EmptyStateMessage(
      icon: Icons.star_border_rounded,
      title: '관심 종목이 없습니다',
      description: '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
    );
  }
}
