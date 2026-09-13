import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/watchlist_sort.dart';
import '../state/watchlist_controller.dart';
import '../theme/theme.dart';

class WatchlistSortButton extends StatelessWidget {
  const WatchlistSortButton({super.key});

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;
    final AppColors colors = context.colors;
    final WatchlistSort sort = context
        .select<WatchlistController, WatchlistSort>(
          (watchlist) => watchlist.sort,
        );

    return TextButton(
      key: const ValueKey<String>('watchlist-sort'),
      onPressed: () async {
        final WatchlistController watchlist = context
            .read<WatchlistController>();
        final WatchlistSort? selected =
            await showModalBottomSheet<WatchlistSort>(
              context: context,
              constraints: const BoxConstraints(maxWidth: 393),
              backgroundColor: colors.surfaceOverlay,
              barrierColor: colors.surfaceBase.withValues(alpha: 0.6),
              barrierLabel: '정렬 선택 닫기',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(dimens.radiusLg),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              showDragHandle: false,
              isScrollControlled: true,
              builder: (_) => _SortSheet(selected: sort),
            );
        if (!context.mounted || selected == null) return;
        watchlist.setSort(selected);
      },
      style: TextButton.styleFrom(
        foregroundColor: colors.textSecondary,
        minimumSize: Size(0, dimens.iconMd + dimens.space2),
        padding: EdgeInsets.symmetric(vertical: dimens.space1),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dimens.radiusSm),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            sort.label,
            style: const TextStyle(
              fontSize: 13,
              height: 18 / 13,
              fontWeight: AppTypography.bold,
            ),
          ),
          Icon(Icons.south_rounded, size: dimens.iconMd),
        ],
      ),
    );
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.selected});

  final WatchlistSort selected;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;
    final AppColors colors = context.colors;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              constraints: BoxConstraints(
                minHeight: dimens.rowMinHeight + dimens.space2,
              ),
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: dimens.space6),
              child: Text(
                '정렬',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 19,
                  height: 22 / 19,
                  letterSpacing: -0.2,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
            for (final WatchlistSort option in WatchlistSort.values)
              Semantics(
                selected: option == selected,
                child: InkWell(
                  key: ValueKey<WatchlistSort>(option),
                  onTap: () => Navigator.of(context).pop(option),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: dimens.space6,
                        vertical: dimens.space3,
                      ),
                      child: Row(
                        children: <Widget>[
                          SizedBox.square(
                            dimension: dimens.space6,
                            child: option == selected
                                ? Icon(
                                    Icons.check_rounded,
                                    size: dimens.iconMd,
                                    color: colors.textPrimary,
                                  )
                                : null,
                          ),
                          SizedBox(width: dimens.space3),
                          Expanded(
                            child: Text(
                              option.label,
                              style: TextStyle(
                                color: option == selected
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                                fontSize: 15,
                                height: 20 / 15,
                                letterSpacing: -0.1,
                                fontWeight: AppTypography.medium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
