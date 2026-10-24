import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/item_repository.dart';
import '../theme/app_theme.dart';

/// "Deleted …" with Undo, after a swipe or detail-screen delete.
void showDeletedSnackBar(
  ScaffoldMessengerState messenger,
  ItemRepository repo,
  Item item,
) {
  SnackBar message(String text, {SnackBarAction? action}) => SnackBar(
    duration: const Duration(seconds: 3),
    content: Text(
      text,
      style: const TextStyle(
        color: Color(0xFFFBF8F2),
        fontWeight: FontWeight.w500,
      ),
    ),
    action: action,
  );

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      message(
        'Deleted "${item.name}"',
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.orange,
          onPressed: () async {
            if (await repo.restore(item)) return;
            // The same name was added again before Undo was tapped.
            messenger
              ..clearSnackBars()
              ..showSnackBar(
                message(
                  '"${item.name}" is already saved again, so it wasn\'t restored',
                ),
              );
          },
        ),
      ),
    );
}
