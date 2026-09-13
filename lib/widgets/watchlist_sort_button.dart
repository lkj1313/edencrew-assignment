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
              backgroundColor: colors.surfaceSunken,
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
        foregroundColor: colors.textTertiary,
        minimumSize: Size(0, dimens.space4 * 2),
        padding: EdgeInsets.symmetric(horizontal: dimens.space2),
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
              fontSize: 12,
              height: 1.5,
              fontWeight: AppTypography.regular,
            ),
          ),
          SizedBox(width: dimens.space1),
          Icon(Icons.south_rounded, size: dimens.iconSm),
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
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dimens.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: dimens.space6),
                child: Text(
                  '정렬',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    height: 1.5,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
              SizedBox(height: dimens.space2),
              for (final WatchlistSort option in WatchlistSort.values)
                Semantics(
                  selected: option == selected,
                  child: InkWell(
                    key: ValueKey<WatchlistSort>(option),
                    onTap: () => Navigator.of(context).pop(option),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: dimens.rowMinHeight,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: dimens.space6,
                          vertical: dimens.space3,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                option.label,
                                style: TextStyle(
                                  color: option == selected
                                      ? colors.textPrimary
                                      : colors.textSecondary,
                                  fontSize: 14,
                                  height: 1.5,
                                  fontWeight: AppTypography.regular,
                                ),
                              ),
                            ),
                            if (option == selected)
                              Icon(
                                Icons.check_rounded,
                                size: dimens.iconMd,
                                color: colors.textPrimary,
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
      ),
    );
  }
}
