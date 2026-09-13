import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/stock_repository.dart';
import '../models/daily_price.dart';
import '../models/stock.dart';
import '../models/stock_quote.dart';
import '../state/stock_detail_controller.dart';
import '../state/watchlist_controller.dart';
import '../theme/theme.dart';
import '../utils/price_format.dart';
import '../widgets/candlestick_chart.dart';
import '../widgets/daily_price_row.dart';
import '../widgets/favorite_toast.dart';
import '../widgets/stock_summary_grid.dart';

void openStockDetail(BuildContext context, Stock stock) {
  FocusManager.instance.primaryFocus?.unfocus();
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => StockDetailScreen(stock: stock)),
  );
}

class StockDetailScreen extends StatelessWidget {
  const StockDetailScreen({super.key, required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<StockDetailController>(
        create: (context) => StockDetailController(
          stock: stock,
          repository: context.read<StockRepository>(),
          watchlist: context.read<WatchlistController>(),
        )..load(),
        child: const _DetailBody(),
      );
}

class _DetailBody extends StatelessWidget {
  const _DetailBody();

  @override
  Widget build(BuildContext context) {
    final StockDetailController detail = context.watch<StockDetailController>();
    final WatchlistController watchlist = context.watch<WatchlistController>();
    final AppDimens dimens = context.dimens;
    final AppColors colors = context.colors;
    final Stock stock = detail.stock;
    final StockQuote? quote = detail.quote;
    final bool favorite = watchlist.isFavorite(stock.symbol);
    return ColoredBox(
      color: colors.surfaceBase,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 393),
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: <Widget>[
                  Container(
                    constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
                    padding: EdgeInsets.symmetric(
                      horizontal: dimens.space1,
                      vertical: dimens.space1,
                    ),
                    foregroundDecoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: colors.borderSubtle,
                          width: dimens.borderHairline,
                        ),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          key: const ValueKey<String>('detail-back'),
                          tooltip: '뒤로 가기',
                          constraints: BoxConstraints.tightFor(
                            width: dimens.iconMd + dimens.space6,
                            height: dimens.iconMd + dimens.space6,
                          ),
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            size: dimens.iconMd,
                            color: colors.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                stock.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 15,
                                  height: 20 / 15,
                                  letterSpacing: -0.1,
                                  fontWeight: AppTypography.medium,
                                ),
                              ),
                              Text(
                                '${stock.symbol} · ${stock.market}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                  height: 14 / 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Semantics(
                          toggled: favorite,
                          child: IconButton(
                            key: const ValueKey<String>('detail-favorite'),
                            constraints: BoxConstraints.tightFor(
                              width: dimens.iconMd + dimens.space6,
                              height: dimens.iconMd + dimens.space6,
                            ),
                            tooltip:
                                '${stock.name} 관심 ${favorite ? '해제' : '등록'}',
                            onPressed: () {
                              final bool registered = watchlist.toggle(stock);
                              showFavoriteToast(
                                context,
                                registered: registered,
                              );
                            },
                            icon: Icon(
                              favorite
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: dimens.iconMd,
                              color: favorite
                                  ? colors.favoriteActive
                                  : colors.favoriteInactive,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CustomScrollView(
                      key: const ValueKey<String>('detail-scroll'),
                      slivers: <Widget>[
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: dimens.space4,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                SizedBox(height: dimens.space3),
                                _CurrentPrice(
                                  quote: quote,
                                  loading: detail.loadingQuote,
                                ),
                                if (detail.quoteError != null)
                                  _RetryMessage(
                                    message: detail.quoteError!,
                                    onRetry: detail.refreshQuote,
                                    buttonKey: 'retry-detail-quote',
                                  ),
                                SizedBox(height: dimens.space4),
                                _PeriodTabs(
                                  selected: detail.period,
                                  onSelected: detail.selectPeriod,
                                ),
                                SizedBox(height: dimens.space4),
                                SizedBox(
                                  height: dimens.space6 * 8 + dimens.space2,
                                  child: detail.loadingHistory
                                      ? Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              CircularProgressIndicator(
                                                color: colors.accentDefault,
                                                semanticsLabel:
                                                    '${detail.period.label} 시세 불러오는 중',
                                              ),
                                              SizedBox(height: dimens.space3),
                                              Text(
                                                '${detail.period.label} 시세를 불러오고 있습니다',
                                                style: TextStyle(
                                                  color: colors.textTertiary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : detail.historyError != null
                                      ? Center(
                                          child: _RetryMessage(
                                            message: detail.historyError!,
                                            onRetry: detail.loadHistory,
                                            buttonKey: 'retry-detail-history',
                                          ),
                                        )
                                      : CandlestickChart(
                                          prices: detail.prices,
                                          period: detail.period,
                                        ),
                                ),
                                SizedBox(height: dimens.space4),
                                StockSummaryGrid(quote: quote),
                                SizedBox(height: dimens.space6),
                                Text(
                                  '일별 시세',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 13,
                                    height: 18 / 13,
                                    fontWeight: AppTypography.bold,
                                  ),
                                ),
                                SizedBox(height: dimens.space1),
                                const DailyPriceRow(),
                              ],
                            ),
                          ),
                        ),
                        if (!detail.loadingHistory &&
                            detail.historyError == null &&
                            detail.prices.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(dimens.space6),
                              child: Text(
                                '조회 가능한 일별 시세가 없습니다',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: dimens.space4,
                          ),
                          sliver: SliverList.builder(
                            itemCount: detail.prices.length,
                            itemBuilder: (context, index) => DailyPriceRow(
                              key: ValueKey<String>(
                                'daily-${detail.prices[index].localDate}',
                              ),
                              price: detail.prices[index],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: dimens.space6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentPrice extends StatelessWidget {
  const _CurrentPrice({required this.quote, required this.loading});
  final StockQuote? quote;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final StockQuote? current = quote;
    final AppColors colors = context.colors;
    if (current == null && loading) {
      return Semantics(
        label: '현재가를 불러오는 중입니다',
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: context.dimens.space6 * 7,
            height: context.dimens.space6 * 2,
            decoration: BoxDecoration(
              color: colors.feedbackSkeleton,
              borderRadius: BorderRadius.circular(context.dimens.radiusSm),
            ),
          ),
        ),
      );
    }
    final Color changeColor = switch (current?.direction) {
      PriceDirection.up => colors.priceUpText,
      PriceDirection.down => colors.priceDownText,
      PriceDirection.flat => colors.priceFlatText,
      null => colors.textTertiary,
    };
    final String direction = switch (current?.direction) {
      PriceDirection.up => '▲ ',
      PriceDirection.down => '▼ ',
      _ => '',
    };
    final int? amount = current?.changeAmount;
    final double? percent = current?.changePercent;
    final String change = amount == null || percent == null
        ? '—'
        : '$direction${formatInteger(amount.abs())} (${percent > 0 ? '+' : ''}${percent.toStringAsFixed(2)}%)';
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        children: <Widget>[
          Text(
            current == null ? '—' : formatInteger(current.currentPrice),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 30,
              height: 36 / 30,
              letterSpacing: -0.4,
              fontWeight: AppTypography.bold,
            ),
          ),
          SizedBox(width: context.dimens.space2),
          Text(
            change,
            style: TextStyle(
              color: changeColor,
              fontSize: 15,
              height: 20 / 15,
              letterSpacing: -0.1,
              fontWeight: AppTypography.medium,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.selected, required this.onSelected});
  final HistoryPeriod selected;
  final ValueChanged<HistoryPeriod> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      for (final HistoryPeriod period in HistoryPeriod.values) ...<Widget>[
        if (period != HistoryPeriod.values.first)
          SizedBox(width: context.dimens.space1),
        Expanded(
          child: Semantics(
            selected: period == selected,
            child: TextButton(
              key: ValueKey<HistoryPeriod>(period),
              onPressed: () => onSelected(period),
              style: TextButton.styleFrom(
                minimumSize: Size(
                  0,
                  context.dimens.iconMd + context.dimens.space2,
                ),
                padding: EdgeInsets.symmetric(vertical: context.dimens.space1),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: period == selected
                    ? context.colors.accentDefault
                    : context.colors.textSecondary,
                backgroundColor: period == selected
                    ? context.colors.accentBg
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.dimens.radiusMd),
                ),
              ),
              child: Text(
                period.label,
                style: const TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: AppTypography.regular,
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

class _RetryMessage extends StatelessWidget {
  const _RetryMessage({
    required this.message,
    required this.onRetry,
    required this.buttonKey,
  });
  final String message;
  final VoidCallback onRetry;
  final String buttonKey;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(
          message,
          style: TextStyle(color: context.colors.feedbackWarning, fontSize: 12),
        ),
      ),
      TextButton(
        key: ValueKey<String>(buttonKey),
        onPressed: onRetry,
        child: const Text('다시 시도'),
      ),
    ],
  );
}
