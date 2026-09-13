import 'package:flutter/material.dart';

import '../models/daily_price.dart';
import '../theme/theme.dart';
import '../utils/price_format.dart';

class DailyPriceRow extends StatelessWidget {
  const DailyPriceRow({super.key, this.price});

  // null이면 동일한 컬럼 폭을 사용하는 표 제목 행입니다.
  final DailyPrice? price;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final DailyPrice? row = price;
    final Color changeColor = row?.changeAmount == null
        ? colors.textTertiary
        : row!.changeAmount! > 0
        ? colors.priceUpText
        : row.changeAmount! < 0
        ? colors.priceDownText
        : colors.priceFlatText;
    Widget cell(String text, {bool left = false, Color? color}) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          height: 14 / 11,
          color: color ?? colors.textSecondary,
        ),
      ),
    );
    return Container(
      constraints: BoxConstraints(minHeight: dimens.space4 * 2),
      padding: EdgeInsets.symmetric(vertical: dimens.space2),
      alignment: Alignment.center,
      foregroundDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colors.borderSubtle,
            width: row == null ? 0 : dimens.borderHairline,
            style: row == null ? BorderStyle.none : BorderStyle.solid,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: dimens.space6 * 2,
            child: cell(row?.displayDate ?? '날짜', left: true),
          ),
          SizedBox(width: dimens.space2),
          Expanded(
            child: cell(
              row == null ? '종가' : formatInteger(row.closePrice),
              color: row == null ? null : colors.textPrimary,
            ),
          ),
          SizedBox(width: dimens.space2),
          Expanded(
            child: cell(
              row == null ? '등락' : formatSignedInteger(row.changeAmount),
              color: row == null ? null : changeColor,
            ),
          ),
          SizedBox(width: dimens.space2),
          Expanded(
            child: cell(
              row == null ? '거래량' : formatInteger(row.accumulatedTradingVolume),
            ),
          ),
        ],
      ),
    );
  }
}
