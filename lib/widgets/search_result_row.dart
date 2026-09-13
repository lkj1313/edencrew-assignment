import 'package:flutter/material.dart';

import '../models/stock.dart';
import '../theme/theme.dart';

class SearchResultRow extends StatelessWidget {
  const SearchResultRow({
    super.key,
    required this.stock,
    required this.query,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final Stock stock;
  final String query;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;
    final AppColors colors = context.colors;
    return Container(
      constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
      padding: EdgeInsets.only(left: dimens.space4, right: dimens.space1),
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
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: dimens.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text.rich(
                    TextSpan(children: _highlightedName(colors)),
                    semanticsLabel: stock.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                  Text(
                    '${stock.symbol} · ${stock.market}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 10,
                      height: 1.5,
                      fontWeight: AppTypography.regular,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: dimens.space2),
          Semantics(
            toggled: isFavorite,
            child: IconButton(
              key: ValueKey<String>('favorite-${stock.symbol}'),
              tooltip: '${stock.name} 관심 ${isFavorite ? '해제' : '등록'}',
              constraints: BoxConstraints.tightFor(
                width: dimens.iconMd + dimens.space6,
                height: dimens.iconMd + dimens.space6,
              ),
              onPressed: onToggleFavorite,
              icon: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                size: dimens.iconMd,
                color: isFavorite
                    ? colors.favoriteActive
                    : colors.favoriteInactive,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _highlightedName(AppColors colors) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) return <TextSpan>[TextSpan(text: stock.name)];
    final String name = stock.name.toLowerCase();
    final List<TextSpan> spans = <TextSpan>[];
    int start = 0;
    int match = name.indexOf(needle);
    while (match != -1) {
      if (match > start) {
        spans.add(TextSpan(text: stock.name.substring(start, match)));
      }
      final int end = match + needle.length;
      spans.add(
        TextSpan(
          text: stock.name.substring(match, end),
          style: TextStyle(color: colors.searchHighlight),
        ),
      );
      start = end;
      match = name.indexOf(needle, start);
    }
    if (start < name.length) {
      spans.add(TextSpan(text: stock.name.substring(start)));
    }
    return spans;
  }
}
