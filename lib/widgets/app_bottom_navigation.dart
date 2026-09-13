import 'package:flutter/material.dart';

import '../theme/theme.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceRaised,
        border: Border(
          top: BorderSide(
            color: context.colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: dimens.tabBarHeight,
          child: Row(
            children: <Widget>[
              _tab(context, 0, '관심', Icons.star_border_rounded),
              _tab(context, 1, '검색', Icons.search_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index, String label, IconData icon) {
    final AppDimens dimens = context.dimens;
    final Color color = selectedIndex == index
        ? context.colors.navActive
        : context.colors.navInactive;
    return Expanded(
      child: Semantics(
        selected: selectedIndex == index,
        button: true,
        label: '$label 탭',
        excludeSemantics: true,
        onTap: () => onSelected(index),
        child: InkWell(
          key: ValueKey<String>('tab-$index'),
          onTap: () => onSelected(index),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: dimens.iconMd, color: color),
                SizedBox(height: dimens.space1),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    height: 1.5,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
