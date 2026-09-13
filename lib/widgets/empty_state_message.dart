import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'empty_state_illustration.dart';

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
            switch (icon) {
              Icons.star_border_rounded => const EmptyStateIllustration(
                kind: EmptyIllustration.star,
              ),
              Icons.search_rounded => const EmptyStateIllustration(
                kind: EmptyIllustration.search,
              ),
              Icons.search_off_rounded => const EmptyStateIllustration(
                kind: EmptyIllustration.noResults,
              ),
              _ => Icon(
                icon,
                size: dimens.iconMd * 2,
                color: colors.textTertiary,
              ),
            },
            SizedBox(height: dimens.space3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 19,
                height: 22 / 19,
                letterSpacing: -0.2,
                fontWeight: AppTypography.bold,
              ),
            ),
            SizedBox(height: dimens.space3),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 11,
                height: 14 / 11,
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
