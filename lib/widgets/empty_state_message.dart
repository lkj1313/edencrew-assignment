import 'package:flutter/material.dart';

import '../theme/theme.dart';

class EmptyStateMessage extends StatelessWidget {
  const EmptyStateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;
    final AppColors colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(dimens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: dimens.iconSm * 2, color: colors.textDisabled),
            SizedBox(height: dimens.space4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 18,
                height: 1.5,
                fontWeight: AppTypography.medium,
              ),
            ),
            SizedBox(height: dimens.space2),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textDisabled,
                fontSize: 12,
                height: 1.5,
                fontWeight: AppTypography.regular,
              ),
            ),
            if (action != null) ...<Widget>[
              SizedBox(height: dimens.space3),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
