import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import 'item_detail_screen.dart';

/// Trailing, non-modal detail pane for expanded iPad windows: the list stays
/// visible and usable while an item is open (master–detail).
class ItemInspector extends StatefulWidget {
  const ItemInspector({super.key, required this.itemId, required this.onClose});

  final String itemId;
  final VoidCallback onClose;

  @override
  State<ItemInspector> createState() => _ItemInspectorState();
}

class _ItemInspectorState extends State<ItemInspector> {
  Stream<Item?>? _item;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _item ??= _watch();
  }

  @override
  void didUpdateWidget(ItemInspector old) {
    super.didUpdateWidget(old);
    if (old.itemId != widget.itemId) _item = _watch();
  }

  Stream<Item?> _watch() =>
      AppScope.of(context).repository.watch(widget.itemId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: StreamBuilder<Item?>(
        stream: _item,
        builder: (context, snapshot) {
          final item = snapshot.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Details',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (item != null) ...[
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => context.push('/edit/${item.id}'),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => confirmDeleteItem(
                          context,
                          item,
                          beforeDelete: widget.onClose,
                        ),
                      ),
                    ],
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: item == null
                    ? const SizedBox.shrink()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        children: [ItemDetailContent(item: item, hero: false)],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
