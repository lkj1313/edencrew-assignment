import 'package:flutter/material.dart';

import '../models/stock_quote.dart';
import '../theme/theme.dart';
import '../utils/price_format.dart';

class StockSummaryGrid extends StatelessWidget {
  const StockSummaryGrid({super.key, required this.quote});

  final StockQuote? quote;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;
    String price(int? value) => value == null ? '—' : formatInteger(value);
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _SummaryCard('시가', price(quote?.openPrice))),
            SizedBox(width: dimens.space2),
            Expanded(child: _SummaryCard('고가', price(quote?.highPrice))),
            SizedBox(width: dimens.space2),
            Expanded(child: _SummaryCard('저가', price(quote?.lowPrice))),
          ],
        ),
        SizedBox(height: dimens.space2),
        Row(
          children: <Widget>[
            Expanded(
              child: _SummaryCard('거래량', formatVolume(quote?.tradingVolume)),
            ),
            SizedBox(width: dimens.space2),
            Expanded(
              child: _SummaryCard(
                '시가총액',
                formatMarketCapitalization(quote?.marketCapitalization),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minHeight: context.dimens.rowMinHeight),
    padding: EdgeInsets.all(context.dimens.space2),
    decoration: BoxDecoration(
      color: context.colors.surfaceSunken,
      borderRadius: BorderRadius.circular(context.dimens.radiusMd),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 11,
            height: 14 / 11,
          ),
        ),
        SizedBox(height: context.dimens.space1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 15,
              height: 20 / 15,
              letterSpacing: -0.1,
              fontWeight: AppTypography.medium,
            ),
          ),
        ),
      ],
    ),
  );
}
