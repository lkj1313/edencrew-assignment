import 'package:flutter/material.dart';

import '../theme/theme.dart';

void showFavoriteToast(BuildContext context, {required bool registered}) {
  final AppDimens dimens = context.dimens;
  final AppColors colors = context.colors;
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  // 빠르게 연속해서 누르면 마지막 동작만 안내합니다.
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.surfaceSunken,
      elevation: 0,
      margin: EdgeInsets.fromLTRB(
        dimens.space4,
        0,
        dimens.space4,
        dimens.space3,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space3,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dimens.radiusLg),
      ),
      content: Row(
        children: <Widget>[
          Icon(
            registered ? Icons.star_rounded : Icons.star_border_rounded,
            size: dimens.iconMd,
            color: registered ? colors.favoriteActive : colors.textSecondary,
          ),
          SizedBox(width: dimens.space2),
          Expanded(
            child: Text(
              registered ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                height: 1.5,
                fontWeight: AppTypography.medium,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
