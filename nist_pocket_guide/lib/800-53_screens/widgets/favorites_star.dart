// widgets/favorites_star.dart

import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';

class FavoriteIconButton extends StatelessWidget {
  final String controlId;
  final double iconSize;
  final void Function()? onTapOverride;

  const FavoriteIconButton({
    super.key,
    required this.controlId,
    this.iconSize = 24.0,
    this.onTapOverride,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: AppDataManager().favoriteIds,
      builder: (context, favorites, _) {
        final isFav = favorites.contains(controlId);
        return IconButton(
          icon: Icon(
            isFav ? Icons.star : Icons.star_border,
            color: isFav ? Colors.amber : null,
            size: iconSize,
          ),
          onPressed: onTapOverride ??
              () {
                AppDataManager().toggleFavorite(controlId);
              },
        );
      },
    );
  }
}
