import 'package:flutter/material.dart';

import '../models/stock.dart';
import '../models/stock_quote.dart';
import '../theme/theme.dart';
import '../utils/price_format.dart';

/// 전달받은 종목 정보를 표시하는 재사용 가능한 목록 한 행입니다.
class StockQuoteRow extends StatelessWidget {
  const StockQuoteRow({super.key, required this.stock, this.quote});

  final Stock stock;
  final StockQuote? quote;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final StockQuote? currentQuote = quote;
    final Color changeColor = switch (currentQuote?.direction) {
      PriceDirection.up => colors.priceUpText,
      PriceDirection.down => colors.priceDownText,
      PriceDirection.flat => colors.priceFlatText,
      null => colors.textTertiary,
    };

    return Container(
      constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space2,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
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
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    height: 1.5,
                  ),
                ),
                Text(
                  '${stock.symbol} · ${stock.market}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 10,
                    fontWeight: AppTypography.regular,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: dimens.space3),
          Expanded(
            child: currentQuote == null
                ? _QuoteSkeleton(stockName: stock.name)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        formatInteger(currentQuote.currentPrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: AppTypography.medium,
                          height: 1.5,
                        ),
                      ),
                      Text(
                        formatPriceChange(currentQuote),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 10,
                          fontWeight: AppTypography.regular,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuoteSkeleton extends StatelessWidget {
  const _QuoteSkeleton({required this.stockName});

  final String stockName;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;
    final BoxDecoration decoration = BoxDecoration(
      color: context.colors.feedbackSkeleton,
      borderRadius: BorderRadius.circular(dimens.radiusSm),
    );

    return Semantics(
      label: '$stockName 시세를 불러오는 중입니다',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Container(
            width: dimens.space6 * 3,
            height: dimens.space3,
            decoration: decoration,
          ),
          SizedBox(height: dimens.space1),
          Container(
            width: dimens.space6 * 2,
            height: dimens.space2,
            decoration: decoration,
          ),
        ],
      ),
    );
  }
}
